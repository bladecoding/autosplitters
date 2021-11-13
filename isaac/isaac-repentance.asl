// AutoSplitter for The Binding of Isaac: Repentance
// Updated by Krakenos
// Original code by Hyphen-ated
// Checkpoint code & pointer annotations by blcd/Zamiel

state("isaac-ng", "1.7.5")
{
    int character:     0x007D2CFC, 0x110;

    // 0x0078A46C - GlobalsPtr
    int wins:          0x007C9B0C, 0xE44;
    int winstreak:     0x007C9B0C, 0x31C;
    int frameCounter: 0x007C9B0C, 0x4A230;


    // 0x0078A454 - GamePtr (which is the same thing as the Lua "game" pointer)
    int timer:   0x007C9AEC, 0x1A2E20;
    int floor:   0x007C9AEC, 0x0;
    int curse:   0x007C9AEC, 0x243528;

    // Checkpoint is a custom item planted at the end of a run in the Racing+ mod
    int cpCount: 0x007C9AEC, 0x1B800, 0x0, 0x15E0, 0xB8C; // "Checkpoint" (ID 739) count

    // Reset is a custom item used by the Racing+ mod to signal the AutoSplitter that the mod is sending the player back to the first character
    int resetCount: 0x007C9AEC, 0x1B800, 0x0, 0x15E0, 0xB90; // "Reset" (ID 740) count

    // Equivalent Lua: Game():GetPlayer(0):GetCollectibleNum(734)
    // 0x1B800  - PlayerVectorPtr
    // 0x0    - Player1
    // 0x15E0 - Player1 CollectibleNum Vector Ptr
    // 0xB8C - Item 739 count - current
    // 0xB90 - Item 740 count - current
}

startup
{
    settings.Add("character_run", true, "Multi-character run");
    settings.SetToolTip("character_run", "Disables auto-resetting when you're past the first split.");
    settings.Add("racing_plus_custom_challenge", false, "You're using the Racing+ custom challenge for multi-character runs", "character_run");
    settings.Add("floor_splits", false, "Split on floors");
    settings.Add("grouped_floors", false, "Combine Basement, Caves, Depths, and Womb into one split each", "floor_splits");
    settings.Add("blck_cndl", false, "You're using the \"BLCK CNDL\" seed (the \"Total Curse Immunity\" Easter Egg) or using the Racing+ mod (which disables curses)", "floor_splits");
}

init
{
    vars.timerDuringFloorChange = 0;
    vars.runStartFrame = 0;
}

isLoading
{
     // In order to sync gametime without any real time estimations this has to return true always.
     return true;
}

gameTime
{
    double fps = 1.0/60.0;
    int elapsedFrames = current.frameCounter - vars.runStartFrame;
    double seconds = Convert.ToDouble(elapsedFrames) * fps;
    double nanosecondTicks = seconds * 10000000;
    long ticks = (long)nanosecondTicks;
    TimeSpan time = new TimeSpan(ticks);
    return time;
}

update
{
    //print("wins: " + current.wins + ", floor: " + current.floor + ", character: " + current.character + ", timer: " + current.timer + ", curse: " + current.curse);
    //print("cpCount: " + current.cpCount);
}

start
{
    if (old.timer == 0 && current.timer != 0)
    {
        vars.timerDuringFloorChange = 0;
        vars.runStartFrame = current.frameCounter;
        return true;
    }
}

reset
{
    // old.timer is 0 immediately during a reset, and also when you're on the main menu
    // this "current.timer < 10" is to stop a reset from happening when you s+q.
    // (unless you s+q during the first 1/3 second of the run, but why would you)
    if (old.timer == 0 && current.timer != 0 && current.timer < 10
        && (!settings["character_run"] || timer.CurrentSplitIndex == 0))
    {
        vars.timerDuringFloorChange = 0;
        return true;
    }

    if (settings["racing_plus_custom_challenge"] && current.resetCount == 1 && old.resetCount != 1 && current.floor != 0)
    {
        return true;
    }
}

split
{
    if (current.wins == old.wins + 1)
    {
        return true;
    }

    if (settings["racing_plus_custom_challenge"] && current.cpCount == 1 && old.cpCount != 1 && current.floor != 0)
    {
        return true;
    }

    if (settings["floor_splits"])
    {
        if (current.floor > old.floor && current.floor > 1 && old.floor > 0
        && (!settings["grouped_floors"] || (current.floor != 2 && current.floor != 4 && current.floor != 6 && current.floor != 8)))
        {
            // when using floor splits, if they just got into an xl floor, we are going to doublesplit
            vars.timerDuringFloorChange = current.timer;
            return true;
        }

        if (vars.timerDuringFloorChange != -1
        && current.timer > vars.timerDuringFloorChange)
        {
            vars.timerDuringFloorChange = -1;
            // if they're in blck_cndl mode, there is no xl even if the xl curse looks like it's on
            // similarly, with grouped floors, there's no split to skip
            if (current.curse == 2 && !settings["blck_cndl"] && !settings["grouped_floors"])
            {
                var model = new TimerModel { CurrentState = timer };
                model.SkipSplit();
            }
        }
    }
}