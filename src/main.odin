package main

import "vendor:raylib"
import "game"
import "engine"

// Timer para evitar ler o disco uma porrada de vezes por segundo
asset_check_timer: f32 = 0.0

main :: proc() {
    raylib.SetConfigFlags({ .WINDOW_HIGHDPI, .VSYNC_HINT, .WINDOW_RESIZABLE })

    monitor: i32 = raylib.GetCurrentMonitor()
    MONITOR_WIDTH: i32 = raylib.GetMonitorWidth(monitor)
    MONITOR_HEIGHT: i32 = raylib.GetMonitorHeight(monitor)
    MONITOR_REFRESH_RATE: i32 = raylib.GetMonitorRefreshRate(monitor)

    raylib.InitWindow(MONITOR_WIDTH, MONITOR_HEIGHT, "Mago Musaranho")

    raylib.SetTargetFPS(MONITOR_REFRESH_RATE)

    if !raylib.IsWindowReady() do return

    // if !raylib.IsWindowFullscreen() do raylib.ToggleFullscreen()

    raylib.HideCursor()

    game.Init_Game()

    raylib.SetExitKey(.KEY_NULL);

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime()

        asset_check_timer += dt
        if asset_check_timer >= 0.5 {
            engine.Update_Watched_Texture(&game.Session_Game_Data.circle_texture)

            asset_check_timer = 0.0
        }

        game.Update_Game(dt)
        game.Draw_Game()
    }

    game.Deinit_Game()
    raylib.CloseWindow()
}