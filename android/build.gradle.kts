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