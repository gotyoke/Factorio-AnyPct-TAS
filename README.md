# Factorio TAS Mod

This project is a Tool-Assisted Speedrun (TAS) mod for the Factorio PC game by Wube Software LTD. The included scripts perform a complete Any% speedrun (single player launches a rocket using a generated map and vanilla game rules, without other mods). Version 0.2.2 does this for Factorio version 0.18 in 1h 21m 20s for a specific map seed. Version 0.0.1 requires Factorio version 0.16.

# Running this mod

You must be running Factorio version 0.18.17. This is a hard requirement, brought about by API changes and bug fixes. You can downgrade to version 0.18.17 through Steam (see the BETAS tab in Factorio - Properties).

Next, enable this mod.

Last, start a new Freeplay game using the following map string:

```>>>eNp1VM9r1EAUnnG7Nq0gRfagoHUPBUVIiFsFWcrOKIqUon+D2eysBLKZdZKAVdA99NjixYte3KsKvXnwtiBIBYWiJ28VLx5UKopehHXeTGY3jdsH7+Wb9+N7701CEDqCDiItVCqxpnzuhQgNqNFZn3e7TNhcsLx7xhdpi9k82JvMItZZtZteLJN7RBP3iBUIHhUZynHCI0gbexLBWAyjPH92pgGFh1LhRUHagVrtQ0g98al+i/TW5hHo8D6qDoegEu3IFFCEe2oELH2ZTB31eZQIHtoxS5Iguln30tv1ZuDFM7bruOddKacnpbQFu5WyyF+td9IwCbphwIS16LhKThQrOjyIk1QwxWy5juJ17X3TJrK7Tk3Vlf0waLcRql6UeknthfHdyubVT3ceEqz3cmgGdjPPoGk8ywZcp/uGFgw4l+NZVPIzB3TTRLbIsiw6Bjq4BkGMN7696P95vd3Af5/+eH+teYPgs1cq33drmw0ZnIYVDozM40cgL80qyHDukCz0keB3b0G+ElyGigoYekGawUoJ4bnDEvXXpakeR2a0hqGpUNxW8tts8tmAD6S4h7yIJSCfB7MFRjUcTYY1pA8opidN9Ng4RdbXUH6G1njDN6btq1z/wiD/v4j8HgXPAp3wGmahYWtkvpRG08j73J42J/qE4hIAyPolffqU/QQUlX7OURPQnwW6t3F55R8eq+Hl<<<```

*When you are done, you will want to disable this mod, otherwise it will try to operate in all of your other maps.*

# Inspiration

Thanks go to Bilka/YourNameHere for the initial design for the TAS mod. The steelaxe% TAS run by Xpert85 got me thinking this could be done for a full rocket launch, if I were persistent enough. AntiElitz got me interested in Factorio speedrunning in the first place. He and Rain9441, Nefrums, and happy_dude have all been active in the Any% speedrun category, all competing for the coveted 1st place on speedrun.com/factorio. You might recognize some components of their base layouts in this speedrun.

My previous version of the Factorio TAS mod performed a launch in 2h 5m 31s in Factorio version 0.16. Version 0.17 and 0.18 brought significant technology and recipe changes that allow for faster speedruns. That, combined with some enhancements to the TAS itself and a good map seed, allow for a much faster TAS speedrun.

As far as I am aware, nobody else has attempted to make a TAS speedrun that meets the Any% category. That makes this a World Record and World First (well second, since I did one in 0.16 too).

# FAQ

## How does the mod work?

The mod executes a task every single tick (there are 60 ticks per second), using a task list that I have created. This basically allows the game to execute up to 60 actions per second. Actions include things like constructing buildings, taking items from chests, handcrafting, setting recipies, etc. Many of these actions can be performed while walking. The mod will execute the tasks as soon as the character is within reach, which minimizes wasted ticks.

## Does this mod work for any map?

While the tasks themselves are specific to this map seed, the LUA script to execute the tasks can be used on any map. One would just need to replace the task list with their own tasks for their own map.

## Why does it require version 0.18.17?

The developers are amazing and continually update Factorio to address bugs, add features, and generally make the game better. The TAS run is so sensitive to changes that even the simplest of them break the run. For example, in 0.18.18 the devs fixed bug #82959 (https://forums.factorio.com/82959) when I was about 60% through the run. Their modification slightly changed the algorithm used to calculate the amount of stone and coal obtained from mining large rocks. That minor change broke the run because even one less piece of coal in the early game meant a burner miner drill ran for 26 fewer seconds, which resulted in 6 fewer iron plates, which I needed for an inserter. This caused a cascade effect for the rest of the run. So rather than fixing the entire run, I decided to stick with version 0.18.17.

## How long did it take to make this mod?

The amount of work that went into this run was monumental. While I did have to make several additions, tweaks, and changes to the mod script as I went, the vast majority of the work was programming the tasks. Each task, and there are over 35,000 of them, must be programmed. Programming the tasks from tick 0 to Victory took several months and 500+ in-game hours (estimated). Much of that time is making small tweaks or additions to the task list, then making sure the changes worked. Frequently, I would find a minor design flaw or an unexpected bottleneck in something I had built earlier in the run. Then I had to go back and adjust that design, which had a cascade effect on the tasks that followed.

## Did you really program 35,000+ tasks?

Not exactly. I created a Python script to generate the task list from a custom shorthand grammar. The list of tasks in that shorthand grammar is still almost 9,400 lines long (including minimal comments and whitespace), and I manually programmed (and subsequently tweaked) all of those lines.

## Where can I get this Python script?

I am working to clean up this Python code and write some documentation, and will put that up on GitHub when I'm done so that others may use it.

## Did you plan out the entire base design from start to finish?

No, the base layout grew fairly organically. I utilized some existing designs that speedrunners typically use, but most I came up with some of my own as I went. During the process I spent some time in Sandbox mode to figure out workable designs with reasonably good ratios. As the base grew, I placed my designs in reasonable locations, leaving room for sub-assemblies that I knew I would need in the future. The fact that this factory is fairly compact is just as much a factor of educated guesses as it is tweaking designs to fit.

## How close is this to the theoretical fastest time?

I don't know, but I think it is unlikely that a single-player run on an ideal map would be able to break the 1 hour barrier. Going faster requires scaling up resources and production in every area. That requires additional materials and space. The extra materials to account for this additional space (namely belts) and the time needed to construct them grow more than linearly, so there are diminishing returns, especially later in the run. That said, the designs in this run are very much human-oriented...since I am merely a human. Layouts that are better for computers are possible with a TAS, which may make a run closer to the 1 hour barrier possible.

## How would you improve this run?

The first bottleneck I would need to address is steel. My plan was to get steel rolling as early as possible to build up extra in buffers. But by the time the steel was needed for electric furnaces, I still didn't have much steel buffered. I had used most of it to construct steel furnaces. Late in the game I added one iron-plate lane's worth of steel production. I would consider adding it much earlier, and perhaps yet another lane for even more.

The next bottleneck would be advanced circuits, which would allow me to produce chemical, production, and utility science packs faster. However, doing that would require scaling up electronic circuits and plastic bars, which in turn means scaling up iron, copper, and oil production. All of these take up a signficant amount of space and materials, and time to build. I didn't know about this bottleneck until late in the run, and I wasn't keen on scrapping hundreds of hours of work to make it happen.

At a higher level, I might consider rearranging the base layout so that I spend time closer to the mall area. A fair amount of time is "wasted" walking to remote locations. I say "wasted" in quotes because it's not really. I used that time to craft materials for the next phase, and I'm constantly resource constrained, so the long walks themselves aren't truly bottlenecks. There are very few instances where long-term progress on the based is significantly stunted by traveling.

There are also some small tweaks. For example, I eventually had to rebuild my steel plate buffer to account for more incoming steel and better distribution. I couldn't update my initial steel plate buffer build otherwise it would make the whole rest of the run go out of whack. If I did it over again, I would build the initial buffer correctly the first time. Honestly though, these minor things might cumulatively save at most 30 seconds.

If I went back and applied the lessons learned above, I could probably squeeze another 3-5 minutes off of the run. That isn't worth the hundreds of hours of my time to make it happen.

## What about robots?

Robots have proven a huge success in human-operated speedruns. They are like having multiple characters on the map working toward the same goal. They provide three major benefits:

1. They allow you to construct a complicated design with minimal work (make it once, then copy-paste).
2. They allow you to construct a design from afar.
3. They allow you to build up a design just as the materials become available.

The TAS is not constrained by benefit #1. Complicated designs are constructed just as quickly as simple designs with the same number of materials. The TAS is not greatly impacted by benefit #2 because of resource constraints. The time it takes to move the character to the build location is usually used to craft the materials I need for that build (or the next one). For similar reasons, the TAS is not greatly impacted by benefit #3 as I usually craft just enough materials needed for the next build then build it almost immediately after the needed materials are available.

The downsides to robots are:

1. They cost extra research and materials to obtain, which could otherwise be used for making science packs.
2. They construct large designs in a patchwork fashion, so that the newly constructued build is only marginally functional until the build is complete.
3. Robot construction typically relies upon a mall, which has a tendency to overproduce items that aren't needed now, and underproduce items that are needed now.

I'm not saying that robots make no sense in a TAS run. However, I believe the TAS mitigates some of the benefits robots uniquely provide, so robots are of diminished value. I made a choice not to use them for this reason. That said, a TAS run with robots may have the potential to improve times, something that may be worth exploration (but not by me).
