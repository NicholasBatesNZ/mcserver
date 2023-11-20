package com.batesnz.minecraft.magic.tasks;

import io.papermc.paper.threadedregions.scheduler.ScheduledTask;
import net.lingala.zip4j.ZipFile;
import org.bukkit.Bukkit;

import java.io.IOException;
import java.util.function.Consumer;

public class UploadWorldTask implements Consumer<ScheduledTask> {

    @Override
    public void accept(ScheduledTask scheduledTask) {
        //TODO: find task name somehow (preferably via property file, worst case check aws for running task)

        try (var zip = new ZipFile("testTag")) {
            zip.addFolder(Bukkit.getWorldContainer());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        //TODO: upload to s3
    }
}
