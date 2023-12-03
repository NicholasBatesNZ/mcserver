package com.batesnz.minecraft.magic.tabcompleters;

import com.batesnz.minecraft.magic.utils.TaskManager;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.command.TabCompleter;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.List;

public class SwitchMapTabCompleter implements TabCompleter {

    private final TaskManager taskManager;

    public SwitchMapTabCompleter(TaskManager taskManager) {
        this.taskManager = taskManager;
    }

    @Override
    public @Nullable List<String> onTabComplete(@NotNull CommandSender sender, @NotNull Command command, @NotNull String label, @NotNull String[] args) {
        return taskManager.getTasks();
    }
}
