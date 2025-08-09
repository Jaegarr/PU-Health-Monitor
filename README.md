# F1 Power Unit Health Monitor (PU Health Monitor)

## Overview

This project is a MATLAB-based Power Unit (PU) Health Monitor designed for Formula 1 race data analysis. It combines real telemetry data extraction using the [FastF1 Python library](https://theoehrly.github.io/Fast-F1/) with synthetic subsystem data generation and health scoring in MATLAB. The goal is to assess the health and driver impact on F1 power units by comparing key telemetry and subsystem parameters.

---

## Features

- Downloads real telemetry data (RPM, throttle, gear, DRS, brake, speed) from official F1 race sessions using FastF1.
- Exports telemetry data as CSV files for easy import into MATLAB.
- Generates synthetic subsystem data:
  - Oil Temperature (random walk + spikes on high throttle)
  - Coolant Temperature (smooth oscillation)
  - Battery State of Charge (SOC) with throttle-dependent dips
- Detects engine shift events and RPM overshoots.
- Calculates subsystem breach penalties and overall PU health scores per lap.
- Produces detailed dashboards with plots and summary tables.
- Designed as a professional, clean codebase demonstrating cross-tool proficiency (Python & MATLAB).

---
