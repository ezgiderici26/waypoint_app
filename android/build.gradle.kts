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
    
    // Inject namespace dynamically to support older packages on newer Android Gradle Plugin (AGP) versions
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    // Set Namespace
                    val namespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestText = manifestFile.readText()
                        val packagePattern = "package=\"([^\"]+)\"".toRegex()
                        val match = packagePattern.find(manifestText)
                        if (match != null) {
                            val packageName = match.groupValues[1]
                            namespaceMethod.invoke(android, packageName)
                        } else {
                            namespaceMethod.invoke(android, "com.example.${project.name.replace("-", "_").replace(".", "_")}")
                        }
                    } else {
                        namespaceMethod.invoke(android, "com.example.${project.name.replace("-", "_").replace(".", "_")}")
                    }
                } catch (e: Exception) {}
            }
        }
    }

    // Force consistent JVM target compatibility for Java and Kotlin tasks ONLY for flutter_jailbreak_detection
    if (project.name == "flutter_jailbreak_detection") {
        afterEvaluate {
            if (project.hasProperty("android")) {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    try {
                        val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                        val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                        val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                        setSourceCompatibility.invoke(compileOptions, JavaVersion.VERSION_11)
                        setTargetCompatibility.invoke(compileOptions, JavaVersion.VERSION_11)
                    } catch (e: Exception) {}
                }
            }
        }
        
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
        
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
