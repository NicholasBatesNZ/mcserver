package com.batesnz.minecraft.magic;

import com.batesnz.minecraft.magic.commands.UploadWorldCommand;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.logger.slf4j.ComponentLogger;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.Optional;

public class Magic extends JavaPlugin {

    public static ComponentLogger logger;

    @Override
    public void onEnable() {
        logger = this.getComponentLogger();

        Optional.ofNullable(
                this.getCommand("uploadworld")).ifPresentOrElse(
                        command -> command.setExecutor(new UploadWorldCommand(this)),
                        () -> logger.error(Component.text("Command not registered"))
                );
    }
}
