package main

import "vendor:raylib"
import "game"
import "engine"

// Resolução virtual (para responsividade do jogo)
VIRTUAL_WIDTH :: 1920
VIRTUAL_HEIGHT :: 1080

// Timer para evitar ler o disco uma porrada de vezes por segundo
asset_check_timer: f32 = 0.0

main :: proc() {
    raylib.SetConfigFlags({ .WINDOW_HIGHDPI, .VSYNC_HINT, .WINDOW_UNDECORATED })

    monitor: i32 = raylib.GetCurrentMonitor()
    MONITOR_WIDTH: i32 = raylib.GetMonitorWidth(monitor)
    MONITOR_HEIGHT: i32 = raylib.GetMonitorHeight(monitor)
    // MONITOR_WIDTH: i32 = 1280
    // MONITOR_HEIGHT: i32 = 720
    MONITOR_REFRESH_RATE: i32 = raylib.GetMonitorRefreshRate(monitor)

    raylib.InitWindow(MONITOR_WIDTH, MONITOR_HEIGHT, "Mago Musaranho")
    raylib.SetTargetFPS(MONITOR_REFRESH_RATE)

    if !raylib.IsWindowReady() do return

    icon_image := raylib.LoadImage("assets/icon.png")
    raylib.SetWindowIcon(icon_image)
    raylib.UnloadImage(icon_image)

    raylib.HideCursor()

    game.Init_Game()

    raylib.SetExitKey(.KEY_NULL);

    target := raylib.LoadRenderTexture(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    raylib.SetTextureFilter(target.texture, .BILINEAR)

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime()

        asset_check_timer += dt
        if asset_check_timer >= 0.5 {
            engine.Update_Watched_Texture(&game.Session_Game_Data.circle_texture)
            engine.Update_Watched_Texture(&game.Player_Data.slow_time_texture)

            asset_check_timer = 0.0
        }

        game.Update_Game(dt)

        raylib.BeginTextureMode(target)
            game.Draw_Game()
        raylib.EndTextureMode()

        raylib.BeginDrawing()
            raylib.ClearBackground(raylib.BLACK)

            scale := min(f32(raylib.GetScreenWidth()) / f32(VIRTUAL_WIDTH), f32(raylib.GetScreenHeight()) / f32(VIRTUAL_HEIGHT))

            // Retangulo da textura virtual
            source_rec := raylib.Rectangle {
                x = 0,
                y = 0,
                width = f32(VIRTUAL_WIDTH),
                height = -f32(VIRTUAL_HEIGHT)
            }

            //Retangulo destino, centralizado na tela real do jogador
            dest_rec := raylib.Rectangle {
                x = (f32(raylib.GetScreenWidth()) - (f32(VIRTUAL_WIDTH) * scale)) * 0.5,
                y = (f32(raylib.GetScreenHeight()) - (f32(VIRTUAL_HEIGHT) * scale)) * 0.5,
                width = f32(VIRTUAL_WIDTH) * scale, 
                height = f32(VIRTUAL_HEIGHT) * scale
            }

            raylib.DrawTexturePro(target.texture, source_rec, dest_rec, {0,0}, 0 , raylib.WHITE)
        raylib.EndDrawing()
    }

    raylib.UnloadRenderTexture(target)

    game.Deinit_Game()
    raylib.CloseWindow()
}