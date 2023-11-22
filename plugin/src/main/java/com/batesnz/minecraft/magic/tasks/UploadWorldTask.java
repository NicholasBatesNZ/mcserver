package com.batesnz.minecraft.magic.tasks;

import io.papermc.paper.threadedregions.scheduler.ScheduledTask;
import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.model.ZipParameters;
import org.bukkit.Bukkit;
import org.bukkit.command.CommandSender;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.function.Consumer;

public class UploadWorldTask implements Consumer<ScheduledTask> {

    private final CommandSender sender;

    public UploadWorldTask(CommandSender sender) {
        this.sender = sender;
    }

    @Override
    public void accept(ScheduledTask scheduledTask) {
        var worldContainer = Bukkit.getWorldContainer();
        var parser = new JSONParser();
        var definitionFile = worldContainer.getAbsolutePath() + "/definition.json";

        String tag;
        try {
            var jsonObject = (JSONObject) parser.parse(new FileReader(definitionFile));
            tag = (String) jsonObject.get("family");
        } catch (ParseException e) {
            sender.sendMessage("Error - corrupt server data");
            return;
        } catch (IOException e) {
            sender.sendMessage("Error - sad files");
            return;
        }

        var zipPath = worldContainer.getAbsolutePath().replaceAll("\\.$", "") + tag + ".zip";

        try {
            Files.deleteIfExists(Path.of(zipPath));
        } catch (IOException e) {
            sender.sendMessage("Error - couldn't delete the old one!");
            return;
        }

        try (var zip = new ZipFile(zipPath)) {
            var params = new ZipParameters();
            params.setIncludeRootFolder(false);
            zip.addFolder(worldContainer, params);
        } catch (IOException e) {
            sender.sendMessage("Error - couldn't zip the zip");
            return;
        }

        sender.sendMessage("Yay! We did the thing");

        //TODO: upload to s3
    }
}
