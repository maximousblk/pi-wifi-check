> **Note**
>
> This project serves as a testament to the capabilities of AI copilots, specifically ChatGPT (GPT-4), which was used exclusively through its web UI to create this. With no reliance on traditional IDEs, terminal operations, syntax checks, and even StackOverflow, the development of this project was unique. No mid-way testing was conducted, showcasing the AI's potential in providing robust solutions and assisting in brainstorming. The AI in this context acts as a "copilot", enhancing your capabilities by reducing redundant tasks. The key to deriving great results is asking the right questions. This project, thus, stands as an exciting demonstration of how AI can amplify human capabilities, without overshadowing them.

# WiFi Check and Auto-Reconnect Script

A Bash script for Raspberry Pi and other Linux systems that checks your WiFi connection and automatically attempts to reconnect if the WiFi is down. The script includes optional features for logging and Prometheus integration.

## Features

- **WiFi Connectivity Check**: Regularly checks whether your system can connect to the internet over WiFi.
- **Automatic Reconnection**: If the WiFi connection is lost, the script will attempt to reestablish it automatically.
- **Logging**: Optionally logs the results of each check and actions taken. These logs can be reviewed using the `journalctl` tool or via a log file, depending on your preference.
- **Prometheus Integration**: If you're using Prometheus for system monitoring, the script can expose the WiFi status as a metric, which can be scraped by Prometheus.
- **Log Rotation**: Automatically rotates and compresses log files if logging is enabled, ensuring efficient usage of disk space.

## Getting Started

### Prerequisites

- A Raspberry Pi or any other Linux system with systemd.
- Basic familiarity with command line operations on Linux.
- (Optional) Prometheus Node Exporter installed and configured with the textfile collector enabled (if you intend to use the Prometheus integration).

### Installation

Clone the repository to your system:

```bash
git clone https://github.com/maximousblk/pi-wifi-check.git
cd pi-wifi-check
```

Run the install script:

```bash
sudo ./install.sh
```

The script will prompt you to decide whether you want to enable logging and Prometheus integration. Enter `y` for yes or `n` for no when prompted.

The script will then set up a systemd service and timer, which will execute the WiFi check script every 5 minutes. If you chose to enable logging, it will also set up log rotation.

## Usage

Once installed, the script will run automatically every 5 minutes. You can monitor its activity and output using either of the following methods:

- **Log File**: If you enabled logging during installation, you can check the log file at `/var/log/wifi-check.log` for the script's output and status reports.
- **Systemd Journal**: You can also check the systemd journal logs regardless of whether you opted for log file creation during installation. Run the following command:

  ```bash
  journalctl -u wifi-check.service
  ```

  This command displays the entire history of the WiFi check service. If you want to monitor the logs in real time, add the `-f` flag:

  ```bash
  journalctl -fu wifi-check.service
  ```

  Please note, you might need to use `sudo` for viewing the systemd journal logs, depending on your system's permissions configuration.

## Prometheus Integration

If you opted for Prometheus integration during installation, the script will create a file at `/var/lib/node_exporter/wifi_check.prom` with the WiFi status as a metric. Make sure your Node Exporter is set up to read textfile collector files from this directory.

The metric exposed by the script is called `wifi_check_status`, and it has a value of 0 when the WiFi is down and 1 when it is up. You can use this metric in your Prometheus queries, dashboards, and alerts. For example, you could retrieve the current WiFi status with the following Prometheus query:

```PromQL
wifi_check_status
```

Please note, the actual metric name in Prometheus will depend on how it's configured in the Node Exporter and the textfile collector.

## Updating

To update the script to the latest version, navigate to the repository's directory and run the install script again:

```bash
cd pi-wifi-check
sudo ./install.sh
```

The script will fetch the latest version from the repository, prompt you to confirm your preferences regarding logging and Prometheus integration, and then update your setup accordingly.

## License

This project is licensed under the MIT License.

> **Warning**
>
> This project presents a unique scenario in the realm of software development. The entire codebase, not just guidance or brainstorming, but every single line of code, was generated through interactions with an AI model, GPT-4, from OpenAI.
>
> This reality is stirring a fair bit of controversy in the developer community, as AI models like GPT-4 are trained on vast amounts of data from the internet, potentially including code snippets and structures licensed under various terms. This raises concerns about how such models may inadvertently generate code that echoes or closely resembles this licensed content, leading to potential licensing conflicts.
>
> While the code here is freely provided under the MIT license, it serves as a fascinating case study into an emerging frontier where traditional licensing models and the authorship of AI-generated code are subjects of ongoing discussion and exploration.
