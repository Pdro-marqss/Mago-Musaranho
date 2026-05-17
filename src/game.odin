// @TODO
// TROCAR NOME DO PROJETO E SUBIR NO GITHUB

package main

import "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:math"


GameState :: enum {
    Main_Menu,
    Playing,
    Paused,
    Game_Over
}

SessionData :: struct {
    score: f32,
    high_score: f32,
    deaths: int,
    game_time: f32,
    enemy_spawn_timer: f32,
    current_spawn_rate: f32,
    current_enemy_speed: f32,
    center_zone: ConquestZone,
    points_fade_text_timer: f32,
    points_fade_text_alpha: f32,
    intro_fade_timer: f32,
    ready_to_show: bool,
    ready_to_show_timer: f32,
    initial_logos_index: int,
    debug_mode: bool,
    enemy_texture: raylib.Texture2D,
    floor_texture: raylib.Texture2D,
    circle_texture: raylib.Texture2D,
    main_menu_background:raylib.Texture2D,
}

Player :: struct {
    pos: raylib.Vector2,
    speed: f32,
    radius: f32,
    texture_idle: raylib.Texture2D,
    texture_run: raylib.Texture2D,
    current_frame: int,
    frame_timer: f32,
    is_running: bool,
    facing_right: bool,
    shield_active: bool,
    shield_timer: f32,
    shield_cooldown: f32,
    shield_texture: raylib.Texture2D,
    shield_frame: int,
    shield_animation_timer: f32,
    skill_icons_atlas_texture: raylib.Texture2D,
    frame_texture: raylib.Texture2D,
    key_e_texture: raylib.Texture2D,
}

Enemy :: struct {
    pos: raylib.Vector2,
    vel: raylib.Vector2,
    width: f32,
    height: f32,
    frame_timer: f32,
    current_frame: int,
}

ConquestZone :: struct {
    pos: raylib.Vector2,
    radius: f32,
    active: bool,
    progress: f32
}


player: Player
enemies: [dynamic]Enemy
session_game_data: SessionData
game_state: GameState

INTRO_FADE_DURATION :: 4.0
SHIELD_DURATION :: 4.0
SHIELD_COOLDOWN :: 10.0

// Reset sessionData 
reset_session :: proc() {
    screen_width := f32(raylib.GetScreenWidth())
    screen_height := f32(raylib.GetScreenHeight())

    session_game_data.score = 0
    session_game_data.game_time = 0
    session_game_data.enemy_spawn_timer = 0

    session_game_data.center_zone.progress = 0

    session_game_data.points_fade_text_timer = 0

    clear(&enemies)

    player.pos = { screen_width / 2, screen_height / 2 }
    player.shield_active = false
    player.shield_timer = 0
    player.shield_cooldown = 0
}


init_game :: proc() {
    // Screen size values
    screen_width: f32 = f32(raylib.GetScreenWidth())
    screen_height: f32 = f32(raylib.GetScreenHeight())

    // GameState
    game_state = .Main_Menu

    // Player default configs
    player = Player{
        pos = {screen_width / 2, screen_height / 2},
        speed = 600.0,
        radius = 30.0,
        texture_idle = raylib.LoadTexture("assets/sprites/MouseIdle.png"),
        texture_run = raylib.LoadTexture("assets/sprites/MouseRun.png"),
        current_frame = 0,
        frame_timer = 0,
        is_running = false,
        facing_right = true,
        shield_texture = raylib.LoadTexture("assets/sprites/RatSpellsAtlas.png"),
        shield_active = false,
        shield_timer = 0,
        shield_cooldown = 0,
        skill_icons_atlas_texture = raylib.LoadTexture("assets/sprites/SkillsIcons.png"),
        frame_texture = raylib.LoadTexture("assets/sprites/SkillFrame.png"),
        key_e_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_e_outline.png"),
    }

    // Default Game Session configs
    session_game_data = SessionData{
        score = 0,
        deaths = 0,
        game_time = 0,
        enemy_spawn_timer = 0,
        center_zone = ConquestZone{
            pos = { screen_width / 2, screen_height / 2 },
            radius = 200.0,
            active = false,
        },
        high_score = load_highscore(),
        current_spawn_rate = 0.6,
        current_enemy_speed = 350.0,
        intro_fade_timer = INTRO_FADE_DURATION,
        debug_mode = false,
        enemy_texture = raylib.LoadTexture("assets/sprites/FireSpellsEffects.png"),
        floor_texture = raylib.LoadTexture("assets/sprites/TextureAtlas.png"),
        circle_texture = raylib.LoadTexture("assets/sprites/MagicArea.png"),
        main_menu_background = raylib.LoadTexture("assets/sprites/MainMenuBg.jpg"),
    }

    raylib.SetTextureFilter(session_game_data.enemy_texture, .POINT)


    // Alocando na memória um espaço para o array dinamico de inimigos caso seja a primeira vez rodando o jogo
    if enemies == nil {
        enemies = make([dynamic]Enemy)
    } else {
        // Limpando os inimigos alocados caso ja exista (no caso de uma morte e reinicio de jogo por exemplo)
        clear(&enemies)
    }
}


update_game :: proc(dt: f32) {
    // initial sync. Only starts to count when window is focused and fullscreen active
    if !session_game_data.ready_to_show {
        // if raylib.IsWindowFocused() && raylib.IsWindowFullscreen() {
        if raylib.IsWindowReady() {
            session_game_data.ready_to_show_timer += dt
            if session_game_data.ready_to_show_timer > 3.0 {
                session_game_data.ready_to_show = true
                session_game_data.ready_to_show_timer = 0
            }
        }
    } else if game_state == .Main_Menu && session_game_data.initial_logos_index < 2 {
        // Control the splashes logos sequency in initial game
        session_game_data.ready_to_show_timer += dt

        //each logo stays 3 seconds on screen
        if session_game_data.ready_to_show_timer > 3.0 {
            session_game_data.initial_logos_index += 1
            session_game_data.ready_to_show_timer = 0
        }
    } else {
        if session_game_data.intro_fade_timer > 0 {
            session_game_data.intro_fade_timer -= dt
        }

        if game_state == .Main_Menu {
            if raylib.IsKeyPressed(.ENTER) || raylib.IsKeyPressed(.KP_ENTER) {
                game_state = .Playing
            }
        } else if game_state == .Game_Over {
            if raylib.IsKeyPressed(.SPACE) {
                reset_session()
                game_state = .Playing
            }
        } else if game_state == .Playing {
            screen_width: f32 = f32(raylib.GetScreenWidth())
            screen_height: f32 = f32(raylib.GetScreenHeight())
        
            if raylib.IsKeyPressed(.ESCAPE) do game_state = .Paused

            session_game_data.game_time += dt
            session_game_data.enemy_spawn_timer += dt
        
            // debug mode
            if raylib.IsKeyPressed(.F3) {
                session_game_data.debug_mode = !session_game_data.debug_mode
                fmt.printf("Debug Mode: %v\n", session_game_data.debug_mode)
            }

            // spell shield
            {
                if raylib.IsKeyPressed(.E) && player.shield_cooldown <= 0 {
                    player.shield_active = true
                    player.shield_timer = SHIELD_DURATION
                    player.shield_cooldown = SHIELD_COOLDOWN
                }
    
                if player.shield_cooldown > 0 {
                    player.shield_cooldown -= dt
                }

                if player.shield_active {
                    player.shield_timer -= dt
                    
                    if player.shield_timer <= 0 {
                        player.shield_active = false
                    }

                    // shield animation (atlas 15x14 = 210 frames)
                    player.shield_animation_timer += dt
                    animation_velocity:f32 = 0.08
                    if player.shield_animation_timer > animation_velocity {
                        player.shield_animation_timer = 0
                        player.shield_frame += 1

                        if player.shield_frame >= 6 do player.shield_frame = 0
                    }
                }
            }

            // Player movement
            player.is_running = false

            {
                if raylib.IsKeyDown(.W) || raylib.IsKeyDown(.UP) {
                    player.pos.y -= player.speed * dt
                    player.is_running = true
                } 
                if raylib.IsKeyDown(.S) || raylib.IsKeyDown(.DOWN) {
                    player.pos.y += player.speed * dt
                    player.is_running = true
                } 
                if raylib.IsKeyDown(.A) || raylib.IsKeyDown(.LEFT) {
                    player.pos.x -= player.speed * dt
                    player.is_running = true
                    player.facing_right = false
                } 
                if raylib.IsKeyDown(.D) || raylib.IsKeyDown(.RIGHT) {
                    player.pos.x += player.speed * dt
                    player.is_running = true
                    player.facing_right = true
                } 
            }

            //player frame control (sprite animation)
            {
                player.frame_timer += dt
                animation_velocity: f32 = 0.1
                animation_max_frames: int = 6

                if player.frame_timer >= animation_velocity {
                    player.frame_timer = 0
                    player.current_frame += 1
                    if player.current_frame >= animation_max_frames {
                        player.current_frame = 0
                    } 
                }
            }
        
            // Secury that player canot get out of the screen bounds
            {
                if player.pos.x < player.radius do player.pos.x = player.radius
                if player.pos.x > screen_width - player.radius do player.pos.x = screen_width - player.radius
                if player.pos.y < player.radius do player.pos.y = player.radius
                if player.pos.y > screen_height - player.radius do player.pos.y = screen_height - player.radius
            }
        
            // ConquestZone collider - Score calc
            {
                if raylib.CheckCollisionCircles(player.pos, player.radius, session_game_data.center_zone.pos, session_game_data.center_zone.radius) {
                    session_game_data.center_zone.active = true
                    session_game_data.center_zone.progress += dt * (1.0 / 3.0)
        
                    if session_game_data.center_zone.progress >= 1.0 {
                        session_game_data.score += 5
                        session_game_data.center_zone.progress = 0
        
                        session_game_data.points_fade_text_timer = 1.0
                        session_game_data.points_fade_text_alpha = 1.0
                    }
                    
                } else {
                    session_game_data.center_zone.active = false
                    session_game_data.center_zone.progress -= dt * 0.5
        
                    if session_game_data.center_zone.progress < 0 do session_game_data.center_zone.progress = 0
                }
            }
        
            // Progressive Dificulty 
            {
                session_game_data.current_spawn_rate = max(0.12, 0.6 - (session_game_data.score * 0.005))
                session_game_data.current_enemy_speed = min(850.0, 350.0 + (session_game_data.score * 2.5))
            }
        
            // Enemies
            {
                // Movement and Collision
                for i := 0; i < len(enemies); {
                    enemy := &enemies[i]
                    enemy.pos += enemy.vel * dt

                    // Fire Animation frame control
                    enemy.frame_timer += dt
                    fire_animation_velocity:f32 = 0.1
                    if enemy.frame_timer >= fire_animation_velocity {
                        enemy.frame_timer = 0
                        enemy.current_frame = (enemy.current_frame + 1) % 6 // runs between 0 - 5
                    }

                    // fire_hitbox: raylib.Rectangle = raylib.Rectangle {
                    //     x = enemy.pos.x - (enemy.width / 2),
                    //     y = enemy.pos.y - (enemy.height / 2),
                    //     width = enemy.width,
                    //     height = enemy.height,
                    // }

                    direction := raylib.Vector2Normalize(enemy.vel)
                    hitbox_center:[2]f32 = enemy.pos + (direction * 15.0)
                    hitbox_radius: f32 = 12.0
                    collision_radius := player.shield_active ? player.radius * 1.8 : player.radius

                    if raylib.CheckCollisionCircles(player.pos, collision_radius, hitbox_center, hitbox_radius) {
                        if player.shield_active {
                            ordered_remove(&enemies, i)
                            continue
                        } else {
                            session_game_data.deaths += 1
                            
                            if session_game_data.score > session_game_data.high_score {
                                session_game_data.high_score = session_game_data.score
                                save_highscore(session_game_data.high_score)
                            }
            
                            game_state = .Game_Over
                            break
                        }
                    }

                    // Clear enemies from screen and memory
                    if enemy.pos.x < -100 || enemy.pos.x > screen_width + 100 || enemy.pos.y < -100 || enemy.pos.y > screen_height + 100{
                        ordered_remove(&enemies, i)
                        continue
                    }

                    i += 1
                } 
        
                // Spawn
                if session_game_data.enemy_spawn_timer > session_game_data.current_spawn_rate {
                    new_enemy: Enemy
                    new_enemy.width = 40.0
                    new_enemy.height = 20.0
        
                    spawn_corner_side := raylib.GetRandomValue(0, 3)
                    switch spawn_corner_side {
                        case 0: //cima
                            new_enemy.pos = { f32(raylib.GetRandomValue(0, i32(screen_width))), -20 }
                        case 1: //baixo
                            new_enemy.pos = { f32(raylib.GetRandomValue(0, i32(screen_width))), screen_height + 20 }
                        case 2: //esquerda
                            new_enemy.pos = { -20, f32(raylib.GetRandomValue(0, i32(screen_height))) }
                        case 3: //direita
                            new_enemy.pos = { screen_width + 20, f32(raylib.GetRandomValue(0, i32(screen_height))) }
                    }
        
                    enemy_direction := raylib.Vector2Normalize(session_game_data.center_zone.pos - new_enemy.pos)
                    new_enemy.vel = enemy_direction * session_game_data.current_enemy_speed
        
                    append(&enemies, new_enemy)
                    session_game_data.enemy_spawn_timer = 0
                }
            }
        
            // Points fade out logic
            {
                if session_game_data.points_fade_text_timer > 0 {
                    session_game_data.points_fade_text_timer -= dt
                    session_game_data.points_fade_text_alpha = session_game_data.points_fade_text_timer / 1.0
                }
            }
        } else if game_state == .Paused {
            if raylib.IsKeyPressed(.ESCAPE) || raylib.IsKeyPressed(.C) do game_state = .Playing
            if raylib.IsKeyPressed(.M) {
                reset_session();
                game_state = .Main_Menu
            }
            if raylib.IsKeyPressed(.Q) do raylib.CloseWindow()
            
            return
        }
    }
}


draw_game :: proc() {
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.BLACK)

    screen_width: f32 = f32(raylib.GetScreenWidth())
    screen_height: f32 = f32(raylib.GetScreenHeight())

    // Draw Grass Tiles
    if game_state == .Playing {
        TILE_SIZE_ATLAS :: 32
        TILE_SCALE :: 2.0
        RENDER_SIZE: f32 = f32(TILE_SIZE_ATLAS) * TILE_SCALE
    
        source_rec := raylib.Rectangle {
            x = f32(4 * TILE_SIZE_ATLAS),
            y = f32(14 * TILE_SIZE_ATLAS),
            width = TILE_SIZE_ATLAS,
            height = TILE_SIZE_ATLAS,
        }
    
        for x : f32 = 0; x < screen_width; x += RENDER_SIZE {
            for y : f32 = 0; y < screen_height; y += RENDER_SIZE {
                dest_rec := raylib.Rectangle {
                    x = x,
                    y = y,
                    width = RENDER_SIZE,
                    height = RENDER_SIZE,
                }
                raylib.DrawTexturePro(session_game_data.floor_texture, source_rec, dest_rec, {0,0}, 0, raylib.WHITE)
            }
        }

        raylib.DrawRectangle(0, 0, i32(screen_width), i32(screen_height) + 1000, raylib.Fade(raylib.BLACK, 0.4))
    }

    // Game Draw
    if game_state == .Playing {

        // Draw ConquestZone
        {
            zone: ConquestZone = session_game_data.center_zone
            tex: raylib.Texture2D = session_game_data.circle_texture

            full_dest_rec := raylib.Rectangle{
                x = zone.pos.x,
                y = zone.pos.y,
                width = zone.radius * 2,
                height = zone.radius * 2,
            }

            origin := raylib.Vector2{ full_dest_rec.width / 2, full_dest_rec.height / 2 }

            source_rec := raylib.Rectangle{
                x = 0,
                y = 0,
                width = f32(tex.width),
                height = f32(tex.height)                
            }

            raylib.DrawTexturePro(tex, source_rec, full_dest_rec, origin, 0, raylib.Fade(raylib.BLACK, 0.4))

            if zone.progress > 0 {
                progress_dest_rec := raylib.Rectangle{
                    x = zone.pos.x,
                    y = zone.pos.y,
                    width = full_dest_rec.width * zone.progress,
                    height = full_dest_rec.height * zone.progress,
                }
                
                progress_origin := raylib.Vector2{ progress_dest_rec.width / 2, progress_dest_rec.height / 2 }
    
                color_tint := zone.active ? raylib.WHITE : raylib.LIGHTGRAY
    
                raylib.DrawTexturePro(tex, source_rec, progress_dest_rec, progress_origin, 0, color_tint)
            }
        }
    
        // Draw Player
        {
            active_tex := player.is_running ? player.texture_run : player.texture_idle
            frame_height := f32(active_tex.height) / 6
            source_rec := raylib.Rectangle {
                x = 0,
                y = f32(player.current_frame) * frame_height,
                width = f32(active_tex.width),
                height = frame_height
            }

            if !player.facing_right {
                source_rec.width *= -1
            }

            sprite_scale:f32 = 6.0

            dest_rec := raylib.Rectangle {
                x = player.pos.x,
                y = player.pos.y,
                width = f32(active_tex.width) * sprite_scale,
                height = frame_height * sprite_scale
            }

            origin := raylib.Vector2{ dest_rec.width / 2, dest_rec.height / 2 }
            raylib.DrawTexturePro(active_tex, source_rec, dest_rec, origin, 0, raylib.WHITE)

            if session_game_data.debug_mode {
                raylib.DrawCircleLinesV(player.pos, player.radius, raylib.LIME)

                raylib.DrawCircle(i32(session_game_data.center_zone.pos.x), i32(session_game_data.center_zone.pos.y), 5, raylib.YELLOW)
            }
        }

        // Draw Spell Shield
        {
            if player.shield_active {
                tex := player.shield_texture

                frame_size: f32 = 64.0
                spell_line_target: f32 = 7.0

                source_rec := raylib.Rectangle {
                    x = f32(player.shield_frame) * frame_size,
                    y = spell_line_target * frame_size,
                    width = frame_size,
                    height = frame_size,
                }

                shield_scale: f32 = 2.5
                dest_rec := raylib.Rectangle {
                    x = player.pos.x,
                    y = player.pos.y,
                    width = frame_size * shield_scale,
                    height = frame_size * shield_scale,
                }

                origin := raylib.Vector2{ dest_rec.width / 2, dest_rec.height / 2 }

                raylib.DrawTexturePro(tex, source_rec, dest_rec, origin, 0, raylib.WHITE)
            }
        }
        
        // Draw Enemies
        {
            for enemy in enemies {
                COLS :: 9
                ROWS :: 30
                FIREBALL_ROW :: 8.0

                text_w: f32 = f32(session_game_data.enemy_texture.width)
                text_h: f32 = f32(session_game_data.enemy_texture.height)

                frame_w: f32 = text_w / COLS
                frame_h: f32 = text_h / ROWS

                angle_rad := math.atan2(enemy.vel.y, enemy.vel.x)
                fireball_angle := angle_rad * raylib.RAD2DEG

                source_rec: raylib.Rectangle = raylib.Rectangle {
                    x = f32(enemy.current_frame) * frame_w,
                    y = FIREBALL_ROW * frame_h,
                    width = frame_w,
                    height = frame_h
                }

                sprite_scale: f32 = 2.0
                dest_rec: raylib.Rectangle = raylib.Rectangle {
                    x = enemy.pos.x,
                    y = enemy.pos.y,
                    width = frame_w * sprite_scale,
                    height = frame_h * sprite_scale
                }

                origin: raylib.Vector2 = raylib.Vector2{ dest_rec.width / 2, dest_rec.height / 2 }

                raylib.DrawTexturePro(session_game_data.enemy_texture, source_rec, dest_rec, origin, fireball_angle, raylib.WHITE)
            
                // Debug fireball
                if session_game_data.debug_mode {
                    direction := raylib.Vector2Normalize(enemy.vel)
                    hitbox_center := enemy.pos + (direction * 15.0)

                    raylib.DrawCircleLinesV(hitbox_center, 12.0, raylib.BLUE)
                    raylib.DrawPixelV(enemy.pos, raylib.YELLOW)
                }
            }
        }

        // Draw Spells HUD
        {   
            base_size: f32 = 90.0  // Aumentado de 64 para 90 para maior visibilidade
            margem_moldura: f32 = 12.0
            
            hud_x := f32(raylib.GetScreenWidth()) / 2 - (base_size / 2)
            hud_y := f32(raylib.GetScreenHeight()) - 120 // Um pouco mais alto por ser maior

            // 1. Ícone
            dest_rect := raylib.Rectangle{ hud_x, hud_y, base_size, base_size }
            raylib.DrawTexturePro(player.skill_icons_atlas_texture, {0,0,32,32}, dest_rect, {0,0}, 0, raylib.WHITE)

            // 2. Máscara de Cooldown (Sombra)
            if player.shield_cooldown > 0 {
                percentage := player.shield_cooldown / 8.0 
                mask_rect := raylib.Rectangle{ hud_x, hud_y, base_size, base_size * percentage }
                raylib.DrawRectangleRec(mask_rect, raylib.Fade(raylib.BLACK, 0.7))
            }

            // 3. Moldura
            dest_moldura := raylib.Rectangle{ 
                hud_x - margem_moldura/2, 
                hud_y - margem_moldura/2, 
                base_size + margem_moldura, 
                base_size + margem_moldura,
            }
            raylib.DrawTexturePro(player.frame_texture, {0,0,f32(player.frame_texture.width), f32(player.frame_texture.height)}, dest_moldura, {0,0}, 0, raylib.WHITE)

            // 4. Tecla [E] com fundo preto para contraste
            tecla_size : f32 = 32.0
            tecla_x := hud_x + base_size - (tecla_size / 1.5)
            tecla_y := hud_y + base_size - (tecla_size / 1.5)
            
            // Quadrado preto de fundo
            raylib.DrawRectangleRec({tecla_x, tecla_y, tecla_size, tecla_size}, raylib.BLACK)
            // A Tecla
            raylib.DrawTexturePro(player.key_e_texture, {0,0,f32(player.key_e_texture.width), f32(player.key_e_texture.height)}, {tecla_x, tecla_y, tecla_size, tecla_size}, {0,0}, 0, raylib.WHITE)

            // --- PARTE 2: TIMER SEGUINDO O RATO ---
            if player.shield_active {
                // Texto em azul claro (SkyBlue)
                // %0.1f mostra apenas uma casa decimal (ex: 2.4)
                timer_str := raylib.TextFormat("%0.1f", player.shield_timer)
                
                // Posiciona o texto acima da cabeça do rato
                // Subtraímos uns 40-50 pixels do Y do player
                text_x := i32(player.pos.x) - raylib.MeasureText(timer_str, 22) / 2
                text_y := i32(player.pos.y) - 90
                
                // Desenha uma bordinha preta (sombra) para o texto não sumir no fundo
                raylib.DrawText(timer_str, text_x + 2, text_y + 2, 22, raylib.BLACK)
                // Texto principal
                raylib.DrawText(timer_str, text_x, text_y, 22, raylib.SKYBLUE)
            }
        }
    
        // Draw UI HUD
        {
            // Points fade text
            if session_game_data.points_fade_text_timer > 0 {
                points_fade_text_in_cstring := fmt.ctprintf("+5 PONTOS")
                points_fade_text_font_size: i32 = 80
    
                points_fade_text_width := raylib.MeasureText(points_fade_text_in_cstring, points_fade_text_font_size)
                
                points_fade_text_pos_x := i32(screen_width / 2) - (points_fade_text_width / 2)
                //floating effect in text (fly a bit)
                points_fade_text_pos_y := i32(200 - (1.0 - session_game_data.points_fade_text_alpha) * 80)
    
                raylib.DrawText(
                    points_fade_text_in_cstring, 
                    points_fade_text_pos_x, 
                    points_fade_text_pos_y, 
                    points_fade_text_font_size, 
                    raylib.Fade(raylib.WHITE, session_game_data.points_fade_text_alpha)
                )
            }
    
    
            // In game infos (in top of the screen)
            score_text_formatted := fmt.ctprintf("PONTOS: %.0f", session_game_data.score) 
            raylib.DrawText(score_text_formatted, 30, 30, 50, raylib.GOLD)
    
            raylib.DrawText(fmt.ctprintf("Tempo: %.1fs", session_game_data.game_time), 30, 90, 40, raylib.RAYWHITE)
            raylib.DrawText(fmt.ctprintf("Mortes: %d", session_game_data.deaths), 30, 140, 40, raylib.RED)
            
            raylib.DrawFPS(raylib.GetScreenWidth() - 120, 30)
        }
        
    }

    // Draw PauseMenu Overlay 
    if game_state == .Paused {
        w := raylib.GetScreenWidth()
        h := raylib.GetScreenHeight()

        raylib.DrawRectangle(0, 0, i32(screen_width), i32(screen_height), raylib.Fade(raylib.BLACK, 0.8))

        paused_text: cstring= fmt.ctprint("JOGO PAUSADO")
        paused_text_font_size: i32 = 60
        paused_text_width: i32 = raylib.MeasureText(paused_text, paused_text_font_size)
        raylib.DrawText(paused_text, i32(screen_width) / 2 - paused_text_width / 2, i32(screen_height) / 2 - 150, paused_text_font_size, raylib.WHITE)

        continue_text: cstring= fmt.ctprint("[C] CONTINUAR")
        continue_text_font_size: i32 = 30
        continue_text_width: i32 = raylib.MeasureText(continue_text, continue_text_font_size)
        raylib.DrawText(continue_text, i32(screen_width) / 2 - continue_text_width / 2, i32(screen_height) / 2 - 20, continue_text_font_size, raylib.LIGHTGRAY)

        main_menu_text: cstring= fmt.ctprint("[M] MENU PRINCIPAL")
        main_menu_text_font_size: i32 = 30
        main_menu_text_width: i32 = raylib.MeasureText(main_menu_text, main_menu_text_font_size)
        raylib.DrawText(main_menu_text, i32(screen_width) / 2 - main_menu_text_width / 2, i32(screen_height) / 2 + 30, main_menu_text_font_size, raylib.LIGHTGRAY)

        quit_text: cstring= fmt.ctprint("[Q] SAIR DO JOGO")
        quit_text_font_size: i32 = 30
        quit_text_width: i32 = raylib.MeasureText(quit_text, quit_text_font_size)
        raylib.DrawText(quit_text, i32(screen_width) / 2 - quit_text_width / 2, i32(screen_height) / 2 + 80, quit_text_font_size, raylib.LIGHTGRAY)

    }

    // Draw GameOver Overlay
    {
        if game_state == .Game_Over {
            w := raylib.GetScreenWidth()
            h := raylib.GetScreenHeight()

            // Turn Background darker
            raylib.DrawRectangle(0, 0, w, h, raylib.Fade(raylib.BLACK, 0.8))

            death_msg: string = "VOCE MORREU!"
            death_msg_font_size: i32 = 60 
            death_msg_width: i32 = raylib.MeasureText(fmt.ctprintf(death_msg), death_msg_font_size)
            raylib.DrawText(fmt.ctprintf(death_msg), i32(screen_width) / 2 - death_msg_width / 2, i32(screen_height) / 2 - 100, death_msg_font_size, raylib.RED)
            
            score_msg: cstring = fmt.ctprintf("Score: %.0f", session_game_data.score)
            score_msg_font_size: i32 = 30
            score_msg_width: i32 = raylib.MeasureText(score_msg, score_msg_font_size)
            raylib.DrawText(score_msg, i32(screen_width) / 2 - score_msg_width / 2, i32(screen_height) / 2, score_msg_font_size, raylib.WHITE)

            highscore_msg: cstring = fmt.ctprintf("Recorde: %.0f", session_game_data.high_score)
            highscore_msg_font_size: i32 = 30
            highscore_msg_width: i32 = raylib.MeasureText(highscore_msg, highscore_msg_font_size)
            raylib.DrawText(highscore_msg, i32(screen_width) / 2 - highscore_msg_width / 2, i32(screen_height) / 2 + 40, highscore_msg_font_size, raylib.GOLD)

            instruction_msg: cstring = fmt.ctprintf("pressione ESPAÇO para tentar de novo")
            instruction_msg_font_size: i32 = 20
            instruction_msg_width: i32 = raylib.MeasureText(instruction_msg, instruction_msg_font_size)
            raylib.DrawText(instruction_msg, i32(screen_width) / 2 - instruction_msg_width / 2, i32(screen_height) / 2 + 120, instruction_msg_font_size, raylib.GRAY)
        }
    }

    // Draw MainMenu
    if game_state == .Main_Menu {
        if !session_game_data.ready_to_show {
            raylib.ClearBackground(raylib.BLACK)
        } else if session_game_data.initial_logos_index == 0 {
            raylib.ClearBackground(raylib.BLACK)
            odin_logo_text: cstring = "MADE WITH ODIN"
            odin_logo_text_font_size: i32 = 30
            odin_logo_text_width: i32 = raylib.MeasureText(odin_logo_text, odin_logo_text_font_size) 
            raylib.DrawText(odin_logo_text, i32(screen_width / 2) - odin_logo_text_width / 2, i32(screen_height / 2), odin_logo_text_font_size, raylib.WHITE)
        } else if session_game_data.initial_logos_index == 1 {
            raylib.ClearBackground(raylib.BLACK)
            musaranho_logo_text: cstring = "MUSARANHO STUDIOS"
            musaranho_logo_text_font_size: i32 = 30
            musaranho_logo_text_width: i32 = raylib.MeasureText(musaranho_logo_text, musaranho_logo_text_font_size) 
            raylib.DrawText(musaranho_logo_text, i32(screen_width / 2) - musaranho_logo_text_width / 2, i32(screen_height / 2), musaranho_logo_text_font_size, raylib.WHITE)
        } else {
            raylib.ClearBackground(raylib.BLACK)

            if raylib.IsKeyPressed(.ESCAPE) do raylib.CloseWindow()

            // Draw main menu Background image
            {
                backgroundMenuTex := session_game_data.main_menu_background
                
                // Actual backgroundMenu texture size
                source_rec := raylib.Rectangle {
                    x = 0,
                    y = 0,
                    width = f32(backgroundMenuTex.width),
                    height = f32(backgroundMenuTex.height),
                }
            
                // Actual screen size
                dest_rec := raylib.Rectangle{
                    x = 0,
                    y = 0,
                    width = screen_width,
                    height = screen_height,
                }
    
                raylib.DrawTexturePro(backgroundMenuTex, source_rec, dest_rec, {0,0}, 0, raylib.WHITE)
            }

            // Game Title
            title_text := "MAGO MUSARANHO"
            title_text_font_size: i32 = 130
            title_text_width := raylib.MeasureText(fmt.ctprintf(title_text), title_text_font_size)
            title_text_pos_y: i32 = 250
            raylib.DrawText(fmt.ctprintf(title_text), i32(screen_width) / 2 - title_text_width / 2, title_text_pos_y, title_text_font_size, raylib.WHITE)

            // Blinking subtitle instruction text
            if i32(raylib.GetTime() * 2) % 2 == 0 {
                subtitle_text := "Pressione Enter para começar"
                subtitle_text_font_size: i32 = 25
                subtitle_text_width := raylib.MeasureText(fmt.ctprintf(subtitle_text), subtitle_text_font_size)
                subtitle_text_pos_y: i32 = title_text_pos_y + title_text_font_size + 40 
                raylib.DrawText(fmt.ctprintf(subtitle_text), i32(screen_width) / 2 - subtitle_text_width / 2, subtitle_text_pos_y, subtitle_text_font_size, raylib.LIGHTGRAY)
            }

            exit_text: cstring = fmt.ctprintf("Pressione ESC para sair")
            exit_text_font_size: i32 = 18
            exit_text_width: i32 = raylib.MeasureText(exit_text, exit_text_font_size)
            exit_text_pos_y: i32 = title_text_pos_y + title_text_font_size + 120 
            raylib.DrawText(exit_text, i32(screen_width) / 2 - exit_text_width / 2, exit_text_pos_y, exit_text_font_size, raylib.LIGHTGRAY)

            // Fade in effect in the first 2 seconds 
            if session_game_data.intro_fade_timer > 0 {
                alpha: f32 = clamp(session_game_data.intro_fade_timer / 3.0, 0.0, 1.0)
                raylib.DrawRectangle(-1000, -1000, 5000, 5000, raylib.Fade(raylib.BLACK, alpha))
            }
        }
    }
    
    raylib.EndDrawing()
}


save_highscore :: proc(score: f32) {
    score_str := fmt.tprintf("%f", score)

    errnone := os.write_entire_file("save.dat", transmute([]u8)score_str)

    // In ODIN, ERROR NONE is 0, that means success. Anything different than that is a error
    if errnone != os.ERROR_NONE {
        fmt.println("ERRO: Não foi possivel salvar o recorde! Código: ", errnone)
    } else {
        fmt.println("Sucesso: Recorde salvo com sucesso.")
    }
}


load_highscore :: proc() -> f32 {
    data, err := os.read_entire_file_from_path("save.dat", context.allocator)

    if err != os.ERROR_NONE {
        // probably a new player
        return 0
    }

    defer delete(data, context.allocator)

    val, ok := strconv.parse_f32(string(data))
    if !ok {
        fmt.println("Erro ao tentar ler o save... arquivo pode estar corrompido.");
        return 0
    }

    return val
}


deinit_game :: proc() {
    // liberar memória aqui
    raylib.UnloadTexture(player.texture_idle)
    raylib.UnloadTexture(player.texture_run)
    raylib.UnloadTexture(player.shield_texture)
    raylib.UnloadTexture(player.skill_icons_atlas_texture)
    raylib.UnloadTexture(player.frame_texture)
    raylib.UnloadTexture(player.key_e_texture)
    raylib.UnloadTexture(session_game_data.main_menu_background)
    raylib.UnloadTexture(session_game_data.enemy_texture)
    raylib.UnloadTexture(session_game_data.floor_texture)
    raylib.UnloadTexture(session_game_data.circle_texture)

    if enemies != nil do delete(enemies)

    enemies = nil

    fmt.println("Memória limpa com sucesso. Até logo, Mago!")
}

// helpers
draw_centered_text :: proc(text: string, y: i32, size: i32, color: raylib.Color) {
    c_str := fmt.ctprintf(text)
    width := raylib.MeasureText(c_str, size)
    screen_w := raylib.GetScreenWidth()
    raylib.DrawText(c_str, screen_w / 2 - width / 2, y, size, color)
}