package com.batesnz.minecraft.magic.tasks;

import io.papermc.paper.threadedregions.scheduler.ScheduledTask;
import net.lingala.zip4j.ZipFile;
import org.bukkit.Bukkit;
import org.bukkit.command.CommandSender;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.FileReader;
import java.io.IOException;
import java.util.function.Consumer;

public class UploadWorldTask implements Consumer<ScheduledTask> {

    private final CommandSender sender;

    public UploadWorldTask(CommandSender sender) {
        this.sender = sender;
    }

    @Override
    public void accept(ScheduledTask scheduledTask) {
        var parser = new JSONParser();
        var file = Bukkit.getWorldContainer().getAbsolutePath() + "/definition.json";

        String tag;
        try {
            var obj = (JSONObject) parser.parse(new FileReader(file));
            tag = (String) obj.get("family");
        } catch (ParseException e) {
            sender.sendMessage("Error - corrupt server data");
            throw new RuntimeException(e);
        } catch (IOException e) {
            sender.sendMessage("Error - sad files");
            throw new RuntimeException(e);
        }

        try (var zip = new ZipFile(tag)) {
            zip.addFolder(Bukkit.getWorldContainer());
        } catch (IOException e) {
            sender.sendMessage("Error - couldn't zip the zip");
            throw new RuntimeException(e);
        }

        //TODO: upload to s3
    }
}
