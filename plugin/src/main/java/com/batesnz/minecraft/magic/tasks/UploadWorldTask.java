package com.batesnz.minecraft.magic.tasks;

import com.batesnz.minecraft.magic.Magic;
import io.papermc.paper.threadedregions.scheduler.ScheduledTask;
import net.kyori.adventure.text.event.ClickEvent;
import net.kyori.adventure.text.event.HoverEvent;
import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.model.ZipParameters;
import org.bukkit.Bukkit;
import org.bukkit.command.CommandSender;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.io.FileReader;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.function.Consumer;

import static net.kyori.adventure.text.Component.text;

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

        var zipPathString = worldContainer.getAbsolutePath().replaceAll("\\.$", "") + tag + ".zip";
        var zipPath = Path.of(zipPathString);

        try {
            Files.deleteIfExists(zipPath);
        } catch (IOException e) {
            sender.sendMessage("Error - couldn't delete the old one!");
            return;
        }

        try (var zip = new ZipFile(zipPathString)) {
            var params = new ZipParameters();
            params.setIncludeRootFolder(false);
            zip.addFolder(worldContainer, params);
        } catch (IOException e) {
            sender.sendMessage("Error - couldn't zip the zip");
            return;
        }

        sender.sendMessage("World has been zipped, uploading now...");

        var bucket = Magic.config.getString("bucket-name");
        var key = Magic.config.getString("world-prefix") + tag + ".zip";

        try (var s3 = S3Client.create()) {
            var putRequest = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .build();

            s3.putObject(putRequest, RequestBody.fromFile(zipPath));
        } catch (S3Exception e) {
            sender.sendMessage("Error - couldn't upload the file");
            return;
        } catch (SdkClientException e) {
            sender.sendMessage("Error - auth on upload");
            return;
        }

        sender.sendMessage("World has been uploaded, generating URL...");

        URL url;
        try (var presigner = S3Presigner.create()) {
            var getRequest = GetObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .build();

            var presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofHours(1))
                    .getObjectRequest(getRequest)
                    .build();

            url = presigner.presignGetObject(presignRequest).url();
        } catch (S3Exception e) {
            sender.sendMessage("Error - couldn't get presigned URL");
            return;
        } catch (SdkClientException e) {
            sender.sendMessage("Error - auth on presigned url");
            return;
        }

        var downloadMessage = text()
                .content("Click to download the world")
                .clickEvent(ClickEvent.openUrl(url))
                .hoverEvent(HoverEvent.showText(text("Download uploaded world")));

        sender.sendMessage(downloadMessage);
    }
}
