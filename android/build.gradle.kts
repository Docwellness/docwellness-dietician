allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // flutter_jailbreak_detection (added for Phase 9, P9-D7) predates AGP
    // 8's mandatory namespace requirement and never declares one in its own
    // build.gradle - "Namespace not specified" otherwise fails the build
    // outright. Same fix docwellness-user already carries for this exact
    // class of unmaintained-plugin issue: read the real package name back
    // out of the plugin's own AndroidManifest.xml rather than hardcoding
    // this one plugin's name here, so it also covers whichever similarly
    // stale plugin hits this next.
    plugins.withId("com.android.library") {
        val libraryExtension = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (libraryExtension.namespace.isNullOrEmpty()) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                    .find(manifestFile.readText())?.groupValues?.get(1)
                if (!pkg.isNullOrEmpty()) {
                    libraryExtension.namespace = pkg
                }
            }
        }

        // Same root cause, second symptom, but scoped to this one plugin by
        // name (NOT applied to every android-library subproject) - an
        // earlier version of this fix forced Java/Kotlin targets to 1.8
        // globally and broke audioplayers_android, which correctly declares
        // its own Java 17 target; overriding that to 1.8 just moved the
        // "Inconsistent JVM-target" failure onto a plugin that was already
        // fine. flutter_jailbreak_detection alone declares neither
        // compileOptions nor kotlinOptions, so its Java compilation
        // defaults to 1.8 while its Kotlin compilation drifts to whatever
        // JVM is running Gradle (21 here) - fix only this plugin.
        if (project.name == "flutter_jailbreak_detection") {
            libraryExtension.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_1_8
                targetCompatibility = JavaVersion.VERSION_1_8
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
