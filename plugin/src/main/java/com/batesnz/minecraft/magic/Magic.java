package com.batesnz.minecraft.magic;

import com.batesnz.minecraft.magic.commands.UploadWorldCommand;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.logger.slf4j.ComponentLogger;
import org.bukkit.configuration.file.FileConfiguration;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Optional;

public class Magic extends JavaPlugin {

    public static ComponentLogger logger;

    public static FileConfiguration config;

    @Override
    public void onEnable() {
        logger = this.getComponentLogger();
        config = this.getConfig();

        Optional.ofNullable(
                this.getCommand("uploadworld")).ifPresentOrElse(
                        command -> command.setExecutor(new UploadWorldCommand(this)),
                        () -> logger.error(Component.text("Command not registered"))
                );
    }
}
