#!/usr/bin/env node

const { spawn } = require("child_process");
const { program } = require("commander");
const readline = require("readline");
const os = require("os");

program.version("1.0.0").description("CLI tool to install and setup Nginx");

const execCommand = (command, args = []) => {
    return new Promise((resolve, reject) => {
        const process = spawn(command, args, { stdio: "inherit" });

        process.on("error", (error) => {
            console.error(`Error executing ${command}: ${error.message}`);
            reject(error);
        });

        process.on("close", (code) => {
            if (code !== 0) {
                reject(new Error(`${command} failed with exit code ${code}`));
            } else {
                resolve();
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

const installNginx = async () => {
    console.log("Installing Nginx...");

    try {
        await execCommand("apt-get", ["update"]);
        await execCommand("apt-get", ["install", "-y", "nginx"]);
        console.log("Nginx installed successfully.");
    } catch (error) {
        console.error("Failed to install Nginx:", error);
    }
};

const setupFirewall = async () => {
    console.log("Setting up firewall for Nginx...");

    try {
        await execCommand("ufw", ["app", "list"]);
        await execCommand("ufw", ["enable"]);
        await execCommand("ufw", ["allow", "Nginx HTTP"]);
        await execCommand("ufw", ["status"]);
    } catch (error) {
        console.error("Failed to configure the firewall:", error);
    }
};

const askForDomainName = () => {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    rl.question(
        "Enter your project's root domain name (e.g., example.com): ",
        (domain) => {
            console.log(`Your project's root domain is: ${domain}`);
            rl.close();
            process.exit(0); // Exit the CLI after the domain name is printed.
        }
    );
};

const installAndSetupNginx = async () => {
    checkRootPrivileges();

    await installNginx();
    await setupFirewall();

    // Ask for domain name after Nginx and firewall setup
    askForDomainName();
};

program
    .command("install")
    .description("Install Nginx and configure firewall")
    .action(installAndSetupNginx);

program.parse(process.argv);
