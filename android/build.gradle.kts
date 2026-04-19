// Archivo: android/build.gradle.kts

plugins {
    // Estas son las herramientas estándar de Android y Flutter
    id("com.android.application") version "8.2.1" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    
    // Esta es la pieza clave para que Firebase funcione
    // Es el "traductor" que lee tu archivo google-services.json
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuración de las carpetas de compilación (estándar en Flutter)
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

// Tarea para limpiar el proyecto cuando hay errores raros
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}