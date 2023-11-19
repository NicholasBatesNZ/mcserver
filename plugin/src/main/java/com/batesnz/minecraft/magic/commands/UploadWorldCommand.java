package com.batesnz.minecraft.magic.commands;

import com.batesnz.minecraft.magic.Magic;
import com.batesnz.minecraft.magic.tasks.UploadWorldTask;
import org.bukkit.Bukkit;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.jetbrains.annotations.NotNull;

import java.util.concurrent.ThreadLocalRandom;

public class UploadWorldCommand implements CommandExecutor {

    private final Magic plugin;

    private int challengeResult = -1;

    public UploadWorldCommand(Magic plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command, @NotNull String label, @NotNull String[] args) {
        if (!sender.isOp()) {
            sender.sendMessage("Y U NO OP");
            return false;
        }

        if (args.length == 0 || challengeResult == -1) {
            var challenge = generateNewChallenge();
            sender.sendMessage("Please don't run this. What is " + challenge[0] + " multiplied by " + challenge[1] + "?");
            sender.sendMessage("Usage: /" + label + " <answer>");
            return true;
        }

        int attempt;
        try {
            attempt = Integer.parseInt(args[0]);
        } catch (NumberFormatException e) {
            sender.sendMessage("Not a number");
            return false;
        }

        if (challengeResult != attempt) {
            sender.sendMessage("Wrong!");
            return false;
        }

        Bukkit.getAsyncScheduler().runNow(plugin, new UploadWorldTask());
        sender.sendMessage("Uploading...");
        return true;
    }

    private int[] generateNewChallenge() {
        int a = ThreadLocalRandom.current().nextInt(1, 100);
        int b = ThreadLocalRandom.current().nextInt(1, 100);
        challengeResult = a * b;
        return new int[]{a, b};
    }
}
