#!/usr/bin/env node

const { exec } = require("child_process");
const { program } = require("commander");
const os = require("os");

program.version("1.0.0").description("CLI tool to install Docker and Nginx");

const execCommand = (command) => {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error: ${stderr}`);
                reject(error);
            } else {
                console.log(stdout);
                resolve(stdout);
            }
        });
    });
};

const checkRootPrivileges = () => {
    if (os.userInfo().uid !== 0) {
        console.error("Error: You need root privileges to run this tool.");
        process.exit(1);
    }
};

const installDocker = async () => {
    console.log("Installing Docker...");

    try {
        await execCommand("apt-get update");
        await execCommand(
            "apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release"
        );
        await execCommand(
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
        );
        await execCommand(
            `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`
        );
        await execCommand("apt-get update");
        await execCommand(
            "apt-get install -y docker-ce docker-ce-cli containerd.io"
        );

        console.log("Docker installed successfully.");
    } catch (error) {
        console.error("Failed to install Docker:", error);
    }
};

const installNginx = async () => {
    console.log("Installing Nginx...");

    try {
        await execCommand("apt-get update");
        await execCommand("apt-get install -y nginx");

        console.log("Nginx installed successfully.");
    } catch (error) {
        console.error("Failed to install Nginx:", error);
    }
};

const installAll = async () => {
    checkRootPrivileges();
    await installDocker();
    await installNginx();
};

program
    .command("install")
    .description("Install Docker and Nginx")
    .action(installAll);

program.parse(process.argv);
