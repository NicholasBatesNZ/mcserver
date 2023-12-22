package com.batesnz.minecraft.magic.utils;

import com.batesnz.minecraft.magic.Magic;
import net.kyori.adventure.text.Component;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.InvocationType;
import software.amazon.awssdk.services.lambda.model.InvokeRequest;
import software.amazon.awssdk.services.resourcegroupstaggingapi.ResourceGroupsTaggingApiClient;
import software.amazon.awssdk.services.resourcegroupstaggingapi.model.GetResourcesRequest;
import software.amazon.awssdk.services.resourcegroupstaggingapi.model.ResourceTagMapping;
import software.amazon.awssdk.services.resourcegroupstaggingapi.model.Tag;
import software.amazon.awssdk.services.resourcegroupstaggingapi.model.TagFilter;

import java.util.List;
import java.util.Objects;

public class TaskManager {

    private final ResourceGroupsTaggingApiClient taggingApiClient;

    private List<ResourceTagMapping> tasks;

    public TaskManager() {
        taggingApiClient = ResourceGroupsTaggingApiClient.create();
        getTasks();
    }

    public List<String> getTasks() {
        var tagFilter = TagFilter.builder()
                .key("ryanFriendly")
                .values("yes")
                .build();

        var request = GetResourcesRequest.builder()
                .resourceTypeFilters("ecs:task-definition")
                .tagFilters(tagFilter)
                .build();

        tasks = taggingApiClient.getResources(request).resourceTagMappingList();

        return tasks.stream()
                .map(ResourceTagMapping::resourceARN)
                .map(arn -> arn.split("/")[1].split(":")[0])
                .toList();
    }

    public String getVersion(String task) {
        String version = "unknown";

        var resource = tasks.stream()
                .filter(x -> x.resourceARN().contains(task))
                .findFirst();

        if (resource.isPresent()) {
            var value = resource.get().tags().stream()
                    .filter(tag -> Objects.equals(tag.key(), "McVersion"))
                    .map(Tag::value)
                    .findFirst();

            if (value.isPresent()) {
                version = value.get();
            }
        }

        return version;
    }

    public boolean setTask(String task) {
        var resource = tasks.stream()
                .filter(x -> x.resourceARN().contains(task))
                .findFirst();

        if (resource.isEmpty()) return false;

        try (var lambda = LambdaClient.create()) {
            var request = InvokeRequest.builder()
                    .functionName("RunTask")
                    .payload(SdkBytes.fromUtf8String("{\"taskDefinition\":\"" + resource.get().resourceARN() + "\"}"))
                    .invocationType(InvocationType.EVENT)
                    .build();

            lambda.invoke(request);
        } catch (Exception e) {
            Magic.logger.error((Component) e);
            return false;
        }

        return true;
    }
}