package com.batesnz.minecraft.magic.commands;

import com.batesnz.minecraft.magic.utils.TaskManager;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.jetbrains.annotations.NotNull;

public class SwitchMapCommand implements CommandExecutor {

    private final TaskManager taskManager;

    public SwitchMapCommand(TaskManager taskManager) {
        this.taskManager = taskManager;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command, @NotNull String label, @NotNull String[] args) {
        if (!sender.isOp()) {
            sender.sendMessage("Y U NO OP");
            return false;
        }

        if (args.length != 1) {
            sender.sendMessage("Please provide the map to switch to");
            return false;
        }

        if (!taskManager.setTask(args[0])) {
            sender.sendMessage("Couldn't switch. " + args[0] + " probably doesn't exist");
            return false;
        }

        sender.sendMessage("Killing. Use Minecraft version " + taskManager.getVersion(args[0]));
        return true;
    }
}
