# Hull & Hearth

**Tagline:** Your Ship is your Home.

This repository contains the foundational Phase 1 implementation for **Hull & Hearth** in Godot 4.x using GDScript.

## Phase 1 Goals (Voxel Foundation)

- Procedural ocean world with island clusters and deep-water channels.
- Height-based biome layering (lowlands and highlands/peaks).
- ARK-style surface ore placement rules:
  - Copper on stone/highlands (common).
  - Iron on mountain peaks (rare).
- Core resource and crafting progression:
  - Metals: Copper, Tin, Iron.
  - Alloy: Bronze (Copper + Tin).
  - Tool tiers: Wood -> Stone -> Copper -> Bronze -> Iron.

## Project Structure

- `scripts/HH_WorldGen.gd` — TideBlock generation parameters and sampling logic.
- `scripts/HH_TechTree.gd` — resource constants, alloy rules, and tier recipes.
- `scripts/HH_Player.gd` — starter player component hooks for spawn and survival interactions.

## Namespace

All runtime classes use the `HH_` namespace convention.
