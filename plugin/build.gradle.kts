plugins {
    id("java")
    id("io.papermc.paperweight.userdev") version "1.5.9"
    id("xyz.jpenilla.run-paper") version "2.2.2"
}

group = "com.batesnz.minecraft.magic"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    paperweight.paperDevBundle("1.20.2-R0.1-SNAPSHOT")
}

tasks {
    assemble {
        dependsOn(reobfJar)
    }

    runServer {
        systemProperty("com.mojang.eula.agree", true)
    }

    processResources {
        val props = mapOf(
                "version" to project.version
        )
        inputs.properties(props)
        filesMatching("plugin.yml") {
            expand(props)
        }
    }
}