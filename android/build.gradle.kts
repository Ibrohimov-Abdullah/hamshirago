allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://artifactory.yandex.net/artifactory/yandex_mobile_sdk_maven/")
            content {
                includeGroup("com.yandex.android")
            }
        }
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.yandex.android" && requested.name == "maps.mobile") {
                useVersion("4.22.0-lite")
            }
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
