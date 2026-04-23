// Archivo: android/build.gradle.kts

plugins {
    // Versiones sincronizadas (Android y Kotlin)
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    
    // Flutter sin versión (lo maneja solo)
    id("dev.flutter.flutter-gradle-plugin") apply false
    
    // EL CAMBIO FINAL: Sincronizado a 4.3.15 para que deje de molestar
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Mapbox SDK: repositorio privado con token de descarga
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                // El usuario siempre es "mapbox"
                username = "mapbox"
                // El token sk. va en gradle.properties como MAPBOX_DOWNLOADS_TOKEN
                password = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").get()
            }
        }
    }
}

// Configuración de las carpetas de compilación
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea para limpiar el proyecto
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}