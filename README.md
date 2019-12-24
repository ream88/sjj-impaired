# "Sing Out Joyfully" to Jehovah - improved for visually impaired

This repo includes the script/app I used to create a MP3 disc for an elderly
visually impaired brother. Each song is automatically announced using its track number
and title by merging it with a file created by [Google Text-to-Speech](https://cloud.google.com/text-to-speech).

## Usage

- Download ["Sing Out Joyfully" to
  Jehovah](https://www.jw.org/en/library/music-songs/sing-out-joyfully/) as a
  `.jwpub` in the language of your choice and put it into `input`.
- Download all the recordings of "Sing Out Joyfully" to Jehovah as a `.zip` and put
  it into `input` as well.
- Run `mix do compile, run`

## Misc

During development, [binwalk](https://github.com/ReFirmLabs/binwalk) was an essential tool which helped me to understand the structure of `.jwpub` files. Go check it out.

[MIT License](./LICENSE.md)
