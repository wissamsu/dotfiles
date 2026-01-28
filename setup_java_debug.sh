#!/bin/bash

echo "Setting up vimspector for Java Spring Boot debugging..."

# Install Java debugging tools
echo "Installing Java debugging tools..."
vim -c "VimspectorInstall java-debug" -c "qa"

# Check if coc-java is installed
echo "Checking coc-java installation..."
vim -c "CocInstall coc-java" -c "qa"

echo "Setup complete!"
echo ""
echo "Usage:"
echo "1. Open a Java Spring Boot project"
echo "2. Set breakpoints with <leader>dd"
echo "3. Start debugging with <leader>di"
echo "4. Continue with <leader>dc"
echo "5. Step over with <leader>dso"
echo "6. Step into with <leader>dsi"
echo "7. Step out with <leader>dsr"
echo "8. Restart with <leader>dr"
echo "9. Stop debugging with <leader>dq"
echo ""
echo "For Spring Boot remote debugging:"
echo "1. Start your app with: mvn spring-boot:run -Dspring-boot.run.jvmArguments=\"-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005\""
echo "2. Use 'Attach to Spring Boot' configuration"