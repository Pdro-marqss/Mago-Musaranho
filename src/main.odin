package main

import "vendor:raylib"

main :: proc() {
    raylib.SetConfigFlags({ .WINDOW_HIGHDPI, .VSYNC_HINT, .WINDOW_RESIZABLE })

    monitor: i32 = raylib.GetCurrentMonitor()
    MONITOR_WIDTH: i32 = raylib.GetMonitorWidth(monitor)
    MONITOR_HEIGHT: i32 = raylib.GetMonitorHeight(monitor)
    MONITOR_REFRESH_RATE: i32 = raylib.GetMonitorRefreshRate(monitor)

    raylib.InitWindow(MONITOR_WIDTH, MONITOR_HEIGHT, "Mago Musaranho")

    raylib.SetTargetFPS(MONITOR_REFRESH_RATE)

    if !raylib.IsWindowReady() do return

    if !raylib.IsWindowFullscreen() do raylib.ToggleFullscreen()

    raylib.HideCursor()

    init_game()

    raylib.SetExitKey(.KEY_NULL);

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime()
        update_game(dt)
        draw_game()
    }

    deinit_game()
    raylib.CloseWindow()
}