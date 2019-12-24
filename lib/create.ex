defmodule Create do
  def run() do
    database = extract_db()

    titles =
      extract_from_database(
        'SELECT ChapterNumber, Title FROM Document WHERE ChapterNumber IS NOT NULL',
        database
      )

    [{album}] = extract_from_database('SELECT Title FROM Document WHERE DocumentId = 0', database)

    extract_songs()
    |> Enum.zip(titles)
    |> Task.async_stream(
      fn {file, song} ->
        create_prefix(song)
        {file, song}
      end,
      timeout: 60_000
    )
    |> Task.async_stream(fn {:ok, song} -> build_mp3(song, album) end, timeout: 60_000)
    |> Stream.run()
  end

  defp extract_songs() do
    [input] = Path.wildcard("input/*.zip")
    {:ok, output} = :zip.unzip(String.to_charlist(input), cwd: 'tmp')

    output |> Enum.map(&to_string/1)
  end

  defp extract_db() do
    [input] = Path.wildcard("input/*.jwpub")

    # Extract `contents`, which again is a zip file.
    {:ok, handle} = :zip.zip_open(String.to_charlist(input), [:memory])
    {:ok, {'contents', contents}} = :zip.zip_get('contents', handle)
    :ok = :zip.zip_close(handle)

    # Extract the `.db` file from `contents`.
    finder =
      &case &1 do
        {_, filename, _, _, _, _} -> to_string(filename) =~ ".db"
        _ -> false
      end

    {:ok, handle} = :zip.zip_open(contents, cwd: 'tmp')
    {:ok, files} = :zip.zip_list_dir(handle)
    {_, filename, _, _, _, _} = Enum.find(files, finder)
    {:ok, database} = :zip.zip_get(filename, handle)
    :ok = :zip.zip_close(handle)

    database
  end

  defp extract_from_database(query, database) do
    {:ok, conn} = :esqlite3.open(database)
    result = :esqlite3.q(query, conn)
    :ok = :esqlite3.close(conn)
    result
  end

  defp build_mp3({file, {track, title}}, album) do
    input = "concat:tmp/prefix_#{track}.mp3|#{file}"

    System.cmd(
      "ffmpeg",
      [
        "-i",
        input,
        "-ac",
        "2",
        "-metadata",
        "album=#{album}",
        "-metadata",
        "title=#{track}. #{title}",
        "-y",
        String.replace(file, "tmp", "output")
      ],
      parallelism: true,
      stderr_to_stdout: true
    )

    {track, title}
  end

  defp create_prefix({track, title}) do
    request = %GoogleApi.TextToSpeech.V1.Model.SynthesizeSpeechRequest{
      audioConfig: %GoogleApi.TextToSpeech.V1.Model.AudioConfig{
        audioEncoding: "MP3",
        sampleRateHertz: 44100,
        speakingRate: 0.9
      },
      input: %GoogleApi.TextToSpeech.V1.Model.SynthesisInput{
        ssml: "<speak>Lied Nummer #{track}<break time=\"500ms\"/>#{title}</speak>"
      },
      voice: %GoogleApi.TextToSpeech.V1.Model.VoiceSelectionParams{
        languageCode: "de-DE",
        name: "de-DE-Wavenet-D"
      }
    }

    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.TextToSpeech.V1.Connection.new(token.token)

    {:ok, response} =
      GoogleApi.TextToSpeech.V1.Api.Text.texttospeech_text_synthesize(
        conn,
        body: request
      )

    File.write("tmp/prefix_#{track}.mp3", Base.decode64!(response.audioContent))
  end
end
