# Factorio-AnyPct-TAS

World's first Factorio any% tool-assisted speed-run (TAS). Inspired by AntiElitz, Rain9441, TAS mods by YourNameHere/Bilka, and the steelaxe% TAS run by Xpert85, this vanilla single-player speed run goes from nothing to satellite launch in 2:05:31. This beats the current world record set by AntiElitz by over 50 minutes! Well he's only human ;)

This mod is only intended to work in Factorio 0.16.51. If the mod API changes, or map generation changes, or game mechanics or recipes change, this run will be useless. I'm sure that will happen soon enough.

## Installation

Copy the AnyPct-TAS folder to your 'mods' directory. For most people this will be inside the directory specified here: [https://wiki.factorio.com/Application_directory#User_data_directory](https://wiki.factorio.com/Application_directory#User_data_directory)

## Running

Run the Scenario "Any% TAS/AnyPctTAS"

## How do I speed this up?

The standard config is to run it at normal speed. To make it run faster, modify line 3 of tasks.lua. For example, changing the number from '1' to '10' will cause the game to run at 10x speed. The launch time is based upon ticks, however, so speeding it up will not affect the run time.

## Can I make changes to the run?

I don't recommend it. Even if you use the right syntax in tasks.lua, the run is fine-tuned to execute commands in a particular order at particular times, so changes are likely to fail miserably.

## What map seed is this?

Seed: 1798420047

Map exchange string:

```>>>eNpjYBBg0GZgYGBm5mFJzk/MYWZl5UrOLyhILdLNL0plYmXlTC4qTUnVzc/MYWZmZUtJLU4tKmFmYGZJyQTTXKl5qbmVukmJxanMQAXpRYnFxYzMzByZRfl5IBOYWVhZihPzUoBKWYtL8vNAAqwlRampxcxMjNylRYl5maW5YIXMrAyM/tsMsxta5BhA+H89g8H//yAMZF0AOhGEQS5lYAQKwABrck5mWhoDQ4MLA4OCIyMDY7XIOveHVVPsGSHyeg5QxgeoSMRuqMiDVigjYjWU0XEYynCYD2PUwxj9DozGYPDZHsGA2FUCNBlqCYcDggGRbAFLMva+3brg+7ELdox/Vn685JuUYM+YKRvqK1D63g4oyQ7UwMgEJ2bNBIGdMB8wwMx8YA+VumnPePYMCLyxZ2QF6RABEQ4WQOKANzB4BPiArAU9QEJBhgHmNDuYMSIOjGlg8A3mk8cwxmV7dH+oODDagAyXAxEnQATYQrjLGKHMSAeIhCRCFqjViAHZ+hSE507CbDyMZDWaG1RgbjBxwOIFNBEVpIDnAtmTAideMMMdAQzBC+wwHjBumRkQ4IO9Xf0UGQBWW5JY<<<```

## Contributions

All alone here, however I did use many ideas from the Factorio-TAS-Playback mod by YourNameHere & Bilka:

[https://github.com/yournamehere/factorio-tas-playback](https://github.com/yournamehere/factorio-tas-playback)
[https://github.com/Bilka2/factorio-tas-playback](https://github.com/Bilka2/factorio-tas-playback)

Inspired by world-record speed runs by AntiElitz and Rain9441, whose runs and Twitch info can be found here: [https://www.speedrun.com/Factorio](https://www.speedrun.com/Factorio)

Also inspired by world-record TAS steelaxe% speed run by Xpert85, which used the mods above: [https://www.youtube.com/watch?v=o8mHgZHcB6E](https://www.youtube.com/watch?v=o8mHgZHcB6E)
