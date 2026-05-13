package com.nkw.backapisumula.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.List;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class FirebaseCloudMessagingService {

    private static final String FIREBASE_SERVICE_ACCOUNT_ENV = "FIREBASE_SERVICE_ACCOUNT_PATH";
    private static final String GOOGLE_APPLICATION_CREDENTIALS_ENV = "GOOGLE_APPLICATION_CREDENTIALS";

    @PostConstruct
    public void initialize() {
        System.out.println("========== FIREBASE INITIALIZATION START ==========");
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                System.out.println("No Firebase apps exist yet. Attempting to initialize one.");
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(loadCredentials())
                        .build();

                System.out.println("Calling FirebaseApp.initializeApp(options)...");
                FirebaseApp.initializeApp(options);
                System.out.println("FirebaseApp initialized successfully!");
            } else {
                System.out.println("Firebase apps already initialized. Names: ");
                FirebaseApp.getApps().forEach(app -> System.out.println("- " + app.getName()));
            }
        } catch (Exception e) {
            System.err.println("CRITICAL ERROR: Failed to initialize Firebase: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("========== FIREBASE INITIALIZATION END ==========");
    }

    private GoogleCredentials loadCredentials() throws Exception {
        GoogleCredentials envCredentials = tryLoadFromEnvironmentPath(FIREBASE_SERVICE_ACCOUNT_ENV);
        if (envCredentials != null) {
            return envCredentials;
        }

        envCredentials = tryLoadFromEnvironmentPath(GOOGLE_APPLICATION_CREDENTIALS_ENV);
        if (envCredentials != null) {
            return envCredentials;
        }

        Path workingDirectory = Paths.get("").toAbsolutePath().normalize();
        List<Path> candidatePaths = List.of(
                workingDirectory.resolve("firebase-service-account.json"),
                workingDirectory.resolve("../firebase-service-account.json").normalize(),
                workingDirectory.resolve("../config/firebase-service-account.json").normalize(),
                workingDirectory.resolve("../secrets/firebase-service-account.json").normalize(),
                workingDirectory.resolve("../../firebase-service-account.json").normalize());

        for (Path candidatePath : candidatePaths) {
            System.out.println("Looking for Firebase credentials at: " + candidatePath);
            if (Files.exists(candidatePath)) {
                try (InputStream inputStream = new FileInputStream(candidatePath.toFile())) {
                    System.out.println("SUCCESS: Loaded Firebase credentials from local file.");
                    return GoogleCredentials.fromStream(inputStream);
                }
            }
        }

        System.out.println("Looking for 'firebase-service-account.json' in classpath...");
        ClassPathResource classPathResource = new ClassPathResource("firebase-service-account.json");
        if (classPathResource.exists()) {
            try (InputStream inputStream = classPathResource.getInputStream()) {
                System.out.println("SUCCESS: Found 'firebase-service-account.json' in classpath.");
                return GoogleCredentials.fromStream(inputStream);
            }
        }

        System.out.println("Attempting to use Google application default credentials...");
        GoogleCredentials credentials = GoogleCredentials.getApplicationDefault();
        System.out.println("SUCCESS: Loaded Google application default credentials.");
        return credentials;
    }

    private GoogleCredentials tryLoadFromEnvironmentPath(String envVarName) throws Exception {
        String envPath = System.getenv(envVarName);
        if (envPath == null || envPath.isBlank()) {
            System.out.println(envVarName + " is not set.");
            return null;
        }

        Path path = Paths.get(envPath);
        System.out.println("Attempting to load Firebase credentials from "
                + envVarName + ": " + path.toAbsolutePath());
        if (!Files.exists(path)) {
            System.out.println("WARNING: Path from " + envVarName + " was not found.");
            return null;
        }

        try (InputStream inputStream = new FileInputStream(path.toFile())) {
            System.out.println("SUCCESS: Loaded Firebase credentials from " + envVarName + ".");
            return GoogleCredentials.fromStream(inputStream);
        }
    }

    public void sendNotificationToTopic(String topic, String title, String body) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setTopic(topic)
                    .setNotification(notification)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Successfully sent message to topic " + topic + ": " + response);
        } catch (Exception e) {
            System.err.println("Error sending FCM notification: " + e.getMessage());
        }
    }
}
