package com.nkw.backapisumula.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;
import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.io.FileInputStream;

@Service
public class FirebaseCloudMessagingService {

    @PostConstruct
    public void initialize() {
        System.out.println("========== FIREBASE INITIALIZATION START ==========");
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                System.out.println("No Firebase apps exist yet. Attempting to initialize one.");
                
                // Tenta carregar o arquivo a partir da pasta resources
                System.out.println("Looking for 'firebase-service-account.json' in classpath...");
                InputStream serviceAccount = getClass().getClassLoader().getResourceAsStream("firebase-service-account.json");
                
                FirebaseOptions options;
                if (serviceAccount != null) {
                    System.out.println("SUCCESS: Found 'firebase-service-account.json' in classpath. Initializing with this file.");
                    options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                } else {
                    // Tenta usar a variável GOOGLE_APPLICATION_CREDENTIALS
                    System.out.println("WARNING: 'firebase-service-account.json' NOT FOUND in classpath.");
                    System.out.println("Attempting to use GOOGLE_APPLICATION_CREDENTIALS environment variable...");
                    String envVar = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
                    System.out.println("GOOGLE_APPLICATION_CREDENTIALS is set to: " + (envVar != null ? envVar : "null"));
                    
                    options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.getApplicationDefault())
                            .build();
                    System.out.println("SUCCESS: Loaded default application credentials.");
                }
                
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
