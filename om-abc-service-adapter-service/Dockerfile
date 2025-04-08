# Use official OpenJDK runtime as base image
FROM eclipse-temurin:17-jre

# Create application directory
WORKDIR /app

# Copy the JAR file into the container
# (Replace 'your-app.jar' with your actual JAR filename)
COPY target/*.jar app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

# Expose the port your app runs on (change 8080 if needed)
EXPOSE 8080