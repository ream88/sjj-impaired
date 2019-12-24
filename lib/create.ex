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
    |> Task.async_stream(&set_metadata(&1, album), timeout: 60_000)
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

  defp set_metadata({file, {track, title}}, album) do
    System.cmd(
      "ffmpeg",
      [
        "-i",
        file,
        "-metadata",
        "album=#{album}",
        "-metadata",
        "title=#{track}. #{title}",
        "-metadata",
        "comment=\"\"",
        "-y",
        String.replace(file, "tmp", "output")
      ],
      parallelism: true,
      stderr_to_stdout: true
    )
  end
end
