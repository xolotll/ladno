@echo off
set APP_HOME=%~dp0
if exist "%APP_HOME%gradle\wrapper\gradle-wrapper.jar" (
  java -classpath "%APP_HOME%gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
  goto :eof
)
where gradle >nul 2>nul && (gradle -p "%APP_HOME%" %* & goto :eof)
echo Gradle wrapper JAR missing. Run flutter create --platforms=android,ios --org com.ladno .
exit /b 1
