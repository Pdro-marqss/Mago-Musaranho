// @TODO
// TROCAR NOME DO PROJETO E SUBIR NO GITHUB

package main

import "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:math"
import "core:strings"


KeybindScheme :: enum {
    MOVE_IN_WASD_SKILLS_IN_ARROWS,
    MOVE_IN_ARROWS_SKIILS_IN_WASD,
    _COUNT,
}

GameState :: enum {
    Main_Menu,
    Playing,
    Paused,
    Game_Over,
    Choosing_Keybinds
}

GameSettings :: struct {
    high_score: f32,
    first_run: bool,
    keybind_scheme: KeybindScheme,
}

SessionData :: struct {
    score: f32,
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
    circle_frame: f32,
    circle_total_frames: f32,
    circle_speed: f32,
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
    key_q_texture: raylib.Texture2D,
    key_w_texture: raylib.Texture2D,
    key_e_texture: raylib.Texture2D,
    key_r_texture: raylib.Texture2D,
    key_a_texture: raylib.Texture2D,
    key_s_texture: raylib.Texture2D,
    key_d_texture: raylib.Texture2D,
    key_up_texture: raylib.Texture2D,
    key_right_texture: raylib.Texture2D,
    key_down_texture: raylib.Texture2D,
    key_left_texture: raylib.Texture2D,
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
game_settings: GameSettings
selected_keybind_option: int

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
        key_q_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_q_outline.png"),
        key_w_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_w_outline.png"),
        key_e_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_e_outline.png"),
        key_r_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_r_outline.png"),
        key_a_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_a_outline.png"),
        key_s_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_s_outline.png"),
        key_d_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_d_outline.png"),
        key_up_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_arrow_up_outline.png"),
        key_right_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_arrow_right_outline.png"),
        key_down_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_arrow_down_outline.png"),
        key_left_texture = raylib.LoadTexture("assets/sprites/keysIcons/keyboard_arrow_left_outline.png"),
    }

    // Iniciate the first bind option as selected
    selected_keybind_option = 0

    // Load game settings
    game_settings = load_game_settings()

    if game_settings.first_run {
        fmt.println("Primeira execução detectada. Direcionando para tela de escolha de binds.")
        game_settings.keybind_scheme = .MOVE_IN_WASD_SKILLS_IN_ARROWS
        game_state = .Choosing_Keybinds
        session_game_data.initial_logos_index = 2
        session_game_data.ready_to_show = true
    } else {
        game_state = .Main_Menu
        session_game_data.ready_to_show = false
        session_game_data.ready_to_show_timer = 0
        session_game_data.initial_logos_index = 0
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
        current_spawn_rate = 0.6,
        current_enemy_speed = 350.0,
        intro_fade_timer = INTRO_FADE_DURATION, 
        debug_mode = false,
        enemy_texture = raylib.LoadTexture("assets/sprites/FireSpellsEffects.png"),
        floor_texture = raylib.LoadTexture("assets/sprites/TextureAtlas.png"),
        circle_texture = raylib.LoadTexture("assets/sprites/MagicArea_128.png"),
        circle_frame = 0.0,
        circle_total_frames = 36,
        circle_speed = 12.0,
        main_menu_background = raylib.LoadTexture("assets/sprites/MainMenuBg.jpg"),
    }

    raylib.SetTextureFilter(session_game_data.circle_texture, .POINT)
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
    } else if game_state == .Choosing_Keybinds {
        if raylib.IsKeyPressed(.LEFT) {
            selected_keybind_option -= 1
            if selected_keybind_option < 0 do selected_keybind_option = int(KeybindScheme._COUNT) - 1
        }
        if raylib.IsKeyPressed(.RIGHT) {
            selected_keybind_option += 1
            if selected_keybind_option >= int(KeybindScheme._COUNT) do selected_keybind_option = 0
        }
        if raylib.IsKeyPressed(.ENTER) || raylib.IsKeyPressed(.SPACE) {
            game_settings.keybind_scheme = KeybindScheme(selected_keybind_option)
            game_settings.first_run = false
            save_game_settings()
            game_state = .Main_Menu
            session_game_data.intro_fade_timer = INTRO_FADE_DURATION
        }
    } else if game_state == .Main_Menu {
        if session_game_data.intro_fade_timer > 0 {
            session_game_data.intro_fade_timer -= dt
        }
        
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
            shield_key_pressed := false

            if game_settings.keybind_scheme == .MOVE_IN_WASD_SKILLS_IN_ARROWS {
                shield_key_pressed = raylib.IsKeyPressed(.UP)
            } else if game_settings.keybind_scheme == .MOVE_IN_ARROWS_SKIILS_IN_WASD {
                shield_key_pressed = raylib.IsKeyPressed(.Q)
            }

            if shield_key_pressed && player.shield_cooldown <= 0 {
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
            if game_settings.keybind_scheme == .MOVE_IN_WASD_SKILLS_IN_ARROWS {
                // WASD MOVEMENT
                if raylib.IsKeyDown(.W) {
                player.pos.y -= player.speed * dt
                player.is_running = true
                } 
                if raylib.IsKeyDown(.S) {
                    player.pos.y += player.speed * dt
                    player.is_running = true
                } 
                if raylib.IsKeyDown(.A) {
                    player.pos.x -= player.speed * dt
                    player.is_running = true
                    player.facing_right = false
                } 
                if raylib.IsKeyDown(.D) {
                    player.pos.x += player.speed * dt
                    player.is_running = true
                    player.facing_right = true
                }    
            } else if game_settings.keybind_scheme == .MOVE_IN_ARROWS_SKIILS_IN_WASD {
                // ARROWS MOVEMENT
                if raylib.IsKeyDown(.UP) {
                player.pos.y -= player.speed * dt
                player.is_running = true
                } 
                if raylib.IsKeyDown(.DOWN) {
                    player.pos.y += player.speed * dt
                    player.is_running = true
                } 
                if raylib.IsKeyDown(.LEFT) {
                    player.pos.x -= player.speed * dt
                    player.is_running = true
                    player.facing_right = false
                } 
                if raylib.IsKeyDown(.RIGHT) {
                    player.pos.x += player.speed * dt
                    player.is_running = true
                    player.facing_right = true
                }
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
                fire_animation_velocity: f32 = 0.1
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
                        
                        if session_game_data.score > game_settings.high_score {
                            game_settings.high_score = session_game_data.score
                            save_game_settings()
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
            session_game_data.intro_fade_timer = INTRO_FADE_DURATION
        }
        if raylib.IsKeyPressed(.Q) do raylib.CloseWindow()
    }
}


draw_game :: proc() {
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.BLACK)

    screen_width: f32 = f32(raylib.GetScreenWidth())
    screen_height: f32 = f32(raylib.GetScreenHeight())

    if game_state == .Choosing_Keybinds {
        // -------------------------------------------------------------
        // VARIÁVEIS DE LAYOUT (Foco em design Ultra-Compacto)
        // -------------------------------------------------------------
        card_width   := screen_width * 0.19  // Bem mais estreito para abraçar o formato das teclas
        card_height  := screen_height * 0.42 // Encurtado para eliminar vazios verticais
        card_spacing := screen_width * 0.06  // Aumentado o espaçamento entre cards para equilibrar a tela
        
        card1_x := screen_width / 2 - card_width - card_spacing / 2
        card2_x := screen_width / 2 + card_spacing / 2
        card_y  := screen_height / 2 - card_height / 2

        key_icon_size: f32 = 45.0 
        key_gap: f32 = 6.0
        
        // Centros horizontais dos cartões para alinhamento absoluto dos blocos
        key_center_x1 := card1_x + card_width / 2
        key_center_x2 := card2_x + card_width / 2

        text_font_size_card_title: i32 = 35
        text_font_size_section: i32    = 16

        // Cabeçalho da Tela Centralizado
        draw_centered_text("ESCOLHA SEU ESQUEMA DE CONTROLE", i32(card_y - 160), 35, raylib.WHITE)
        draw_centered_text("Selecione o preset ideal para o seu estilo de jogo:", i32(card_y - 95), 21, raylib.LIGHTGRAY)

        // =================================================================
        // CARD 1: MOVIMENTO EM WASD / SKILLS NAS SETAS
        // =================================================================
        card1_rec := raylib.Rectangle{card1_x, card_y, card_width, card_height}
        card1_color := raylib.Fade(raylib.DARKGRAY, 0.4)
        card1_border_color := raylib.DARKGRAY

        if selected_keybind_option == int(KeybindScheme.MOVE_IN_WASD_SKILLS_IN_ARROWS) {
            card1_color = raylib.Fade(raylib.BLUE, 0.15)
            card1_border_color = raylib.BLUE
        }
        raylib.DrawRectangleRounded(card1_rec, 0.08, 8, card1_color)
        raylib.DrawRectangleRoundedLinesEx(card1_rec, 0.08, 8, 2.5, card1_border_color)

        // Título Principal - Preset A
        title1_w := raylib.MeasureText(fmt.ctprintf("PRESET A"), text_font_size_card_title)
        raylib.DrawText(fmt.ctprintf("PRESET A"), i32(key_center_x1 - f32(title1_w)/2), i32(card_y + card_height * 0.05), text_font_size_card_title, raylib.WHITE)

        // --- SUB-SEÇÃO 1: MOVIMENTO (WASD) ---
        move_sec_y1 := card_y + card_height * 0.27
        txt_move1_w := raylib.MeasureText(fmt.ctprintf("MOVIMENTO"), text_font_size_section)
        raylib.DrawText(fmt.ctprintf("MOVIMENTO"), i32(key_center_x1 - f32(txt_move1_w)/2), i32(move_sec_y1), text_font_size_section, raylib.SKYBLUE)

        // Grid WASD aproximado do texto (distância reduzida de 42 para 35)
        w_key_y1 := move_sec_y1 + 52
        draw_keyboard_icon(player.key_w_texture, {key_center_x1, w_key_y1}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_a_texture, {key_center_x1 - (key_icon_size + key_gap), w_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_s_texture, {key_center_x1, w_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_d_texture, {key_center_x1 + (key_icon_size + key_gap), w_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)

        // --- SUB-SEÇÃO 2: HABILIDADES (SETAS) ---
        // Puxado significativamente para cima (fator 0.58 virou 0.52) para esmagar o espaço vazio central
        skill_sec_y1 := card_y + card_height * 0.58
        txt_skill1_w := raylib.MeasureText(fmt.ctprintf("HABILIDADES"), text_font_size_section)
        raylib.DrawText(fmt.ctprintf("HABILIDADES"), i32(key_center_x1 - f32(txt_skill1_w)/2), i32(skill_sec_y1), text_font_size_section, raylib.GOLD)

        // Grid Setas aproximado do texto (distância de 35)
        up_key_y1 := skill_sec_y1 + 52
        draw_keyboard_icon(player.key_up_texture, {key_center_x1, up_key_y1}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_left_texture, {key_center_x1 - (key_icon_size + key_gap), up_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_down_texture, {key_center_x1, up_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_right_texture, {key_center_x1 + (key_icon_size + key_gap), up_key_y1 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)


        // =================================================================
        // CARD 2: MOVIMENTO NAS SETAS / SKILLS EM QWER
        // =================================================================
        card2_rec := raylib.Rectangle{card2_x, card_y, card_width, card_height}
        card2_color := raylib.Fade(raylib.DARKGRAY, 0.4)
        card2_border_color := raylib.DARKGRAY

        if selected_keybind_option == int(KeybindScheme.MOVE_IN_ARROWS_SKIILS_IN_WASD) {
            card2_color = raylib.Fade(raylib.BLUE, 0.15)
            card2_border_color = raylib.BLUE
        }
        raylib.DrawRectangleRounded(card2_rec, 0.08, 8, card2_color)
        raylib.DrawRectangleRoundedLinesEx(card2_rec, 0.08, 8, 2.5, card2_border_color)

        // Título Principal - Preset B
        title2_w := raylib.MeasureText(fmt.ctprintf("PRESET B"), text_font_size_card_title)
        raylib.DrawText(fmt.ctprintf("PRESET B"), i32(key_center_x2 - f32(title2_w)/2), i32(card_y + card_height * 0.05), text_font_size_card_title, raylib.WHITE)

        // --- SUB-SEÇÃO 1: MOVIMENTO (SETAS) ---
        move_sec_y2 := card_y + card_height * 0.25
        txt_move2_w := raylib.MeasureText(fmt.ctprintf("MOVIMENTO"), text_font_size_section)
        raylib.DrawText(fmt.ctprintf("MOVIMENTO"), i32(key_center_x2 - f32(txt_move2_w)/2), i32(move_sec_y2), text_font_size_section, raylib.SKYBLUE)

        // Grid Setas aproximado do texto (distância de 28)
        up_key_y2 := move_sec_y2 + 52
        draw_keyboard_icon(player.key_up_texture, {key_center_x2, up_key_y2}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_left_texture, {key_center_x2 - (key_icon_size + key_gap), up_key_y2 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_down_texture, {key_center_x2, up_key_y2 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_right_texture, {key_center_x2 + (key_icon_size + key_gap), up_key_y2 + (key_icon_size + key_gap)}, key_icon_size, raylib.WHITE)

        // --- SUB-SEÇÃO 2: HABILIDADES (QWER) ---
        // Puxado na mesma altura milimétrica do Card 1
        skill_sec_y2 := card_y + card_height * 0.58
        txt_skill2_w := raylib.MeasureText(fmt.ctprintf("HABILIDADES"), text_font_size_section)
        raylib.DrawText(fmt.ctprintf("HABILIDADES"), i32(key_center_x2 - f32(txt_skill2_w)/2), i32(skill_sec_y2), text_font_size_section, raylib.GOLD)

        // Linha Q W E R (Aproximada e perfeitamente centrada no novo card fino)
        q_key_y2 := skill_sec_y2 + 52 
        row_width := (4.0 * key_icon_size) + (3.0 * key_gap)
        start_x2  := key_center_x2 - row_width / 2

        draw_keyboard_icon(player.key_q_texture, {start_x2 + key_icon_size/2, q_key_y2}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_w_texture, {start_x2 + key_icon_size/2 + (key_icon_size + key_gap), q_key_y2}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_e_texture, {start_x2 + key_icon_size/2 + 2.0 * (key_icon_size + key_gap), q_key_y2}, key_icon_size, raylib.WHITE)
        draw_keyboard_icon(player.key_r_texture, {start_x2 + key_icon_size/2 + 3.0 * (key_icon_size + key_gap), q_key_y2}, key_icon_size, raylib.WHITE)

        // -------------------------------------------------------------
        // RODAPÉ INFORMATIVO
        // -------------------------------------------------------------
        draw_centered_text("Use ESQUERDA / DIREITA para alternar", i32(screen_height - 105), 22, raylib.RAYWHITE)
        draw_centered_text("ENTER para confirmar", i32(screen_height - 65), 22, raylib.RAYWHITE)
        
    }

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
            magic_circle_texture := session_game_data.circle_texture
            magic_circle_total_frames := session_game_data.circle_total_frames
            magic_circle_frame_width := f32(magic_circle_texture.width) / magic_circle_total_frames
            magic_circle_frame_height := f32(magic_circle_texture.height)

            //adjust sprite size to conquestZoneRadius size
            target_width := session_game_data.center_zone.radius * 2.0
            target_height := session_game_data.center_zone.radius * 2.0
        
            dest_rec := raylib.Rectangle{
                x = session_game_data.center_zone.pos.x,
                y = session_game_data.center_zone.pos.y,
                width = target_width,
                height = target_height
            }

            origin := raylib.Vector2{ target_width / 2, target_height / 2 }

            // Static Magic Circle draw on the ground
            source_rec_gravura := raylib.Rectangle{
                x = 35.0 * magic_circle_frame_width,
                y = 0,
                width = magic_circle_frame_width,
                height = magic_circle_frame_height,
            }

            raylib.DrawTexturePro(magic_circle_texture, source_rec_gravura, dest_rec, origin, 0, raylib.Fade(raylib.BLACK, 0.1))

            // Draw conquestZone animation
            current_frame := i32(session_game_data.center_zone.progress * 35.0)

            source_rec_animacao := raylib.Rectangle{
                x = f32(current_frame) * magic_circle_frame_width,
                y = 0,
                width = magic_circle_frame_width,
                height = magic_circle_frame_height,
            }

            if session_game_data.center_zone.progress > 0.0 {
                raylib.DrawTexturePro(magic_circle_texture, source_rec_animacao, dest_rec, origin, 0, raylib.WHITE)
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
            
            // Desenha a Tecla baseado no keybind configurado
            if game_settings.keybind_scheme == .MOVE_IN_WASD_SKILLS_IN_ARROWS {
                raylib.DrawTexturePro(player.key_up_texture, {0,0,f32(player.key_e_texture.width), f32(player.key_e_texture.height)}, {tecla_x, tecla_y, tecla_size, tecla_size}, {0,0}, 0, raylib.WHITE)
            } else if game_settings.keybind_scheme == .MOVE_IN_ARROWS_SKIILS_IN_WASD {
                raylib.DrawTexturePro(player.key_q_texture, {0,0,f32(player.key_e_texture.width), f32(player.key_e_texture.height)}, {tecla_x, tecla_y, tecla_size, tecla_size}, {0,0}, 0, raylib.WHITE)
            }

            // --- PARTE 2: TIMER SEGUINDO O RATO ---
            if player.shield_active {
                // Texto em azul claro (SkyBlue)
                // %0.1f mostra apenas uma casa decimal (ex: 2.4)
                timer_str := raylib.TextFormat("%0.1f", player.shield_timer)
                
                // Posiciona o texto acima da cabeça do rato
                // Subtraímos uns 40-50 pixels do Y do player
                text_x := i32(player.pos.x) - raylib.MeasureText(timer_str, 22) / 2
                text_y := i32(player.pos.y) - 90
                
                // Draw spellShield timer in numbers
                {
                    // Desenha uma bordinha preta (sombra) para o texto não sumir no fundo
                    // raylib.DrawText(timer_str, text_x + 2, text_y + 2, 22, raylib.BLACK)
                    // raylib.DrawText(timer_str, text_x + 2, text_y, 22, raylib.BLACK)
                    // raylib.DrawText(timer_str, text_x - 2, text_y, 22, raylib.BLACK)
                    // raylib.DrawText(timer_str, text_x, text_y + 2, 22, raylib.BLACK)
                    // raylib.DrawText(timer_str, text_x, text_y - 2, 22, raylib.BLACK)
    
                    // Texto principal
                    // raylib.DrawText(timer_str, text_x, text_y, 22, raylib.WHITE)
                }

                // --- BARRA DE PROGRESSO COM OUTLINE ---
                {
                    bar_width: f32 = 40.0
                    bar_height: f32 = 8.0
                    bar_x := player.pos.x - (bar_width / 2)
                    bar_y := player.pos.y - 80
                    outline_thickness: f32 = 3.0 // Grossura da borda

                    // 1. Desenha o Outline (Um retângulo preto maior que fica por baixo)
                    raylib.DrawRectangleV(
                        {bar_x - outline_thickness, bar_y - outline_thickness}, 
                        {bar_width + (outline_thickness * 2), bar_height + (outline_thickness * 2)}, 
                        raylib.BLACK,
                    )

                    // 2. Fundo da barrinha (Cinza escuro para mostrar o "vazio" da barra)
                    raylib.DrawRectangleV({bar_x, bar_y}, {bar_width, bar_height}, raylib.DARKGRAY)

                    // 3. Progresso (Branco)
                    progress := player.shield_timer / SHIELD_DURATION 
                    raylib.DrawRectangleV({bar_x, bar_y}, {bar_width * progress, bar_height}, raylib.WHITE)
                }
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

            highscore_msg: cstring = fmt.ctprintf("Recorde: %.0f", game_settings.high_score)
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


save_game_settings :: proc() {
    first_run_int := game_settings.first_run ? 1 : 0
    keybind_scheme_int := int(game_settings.keybind_scheme)

    settings_str := fmt.tprintf("%.2f;%d;%d", game_settings.high_score, first_run_int, keybind_scheme_int)

    errnone := os.write_entire_file("settings.dat", transmute([]u8)settings_str)

    // In ODIN, ERROR NONE is 0, that means success. Anything different than that is a error
    if errnone != os.ERROR_NONE {
        fmt.println("ERRO: Não foi possivel salvar as configurações do jogo! Código: ", errnone)
    } else {
        fmt.println("Sucesso: Configurações do jogo salvas com sucesso.")
    }
}


load_game_settings :: proc() -> GameSettings {
    data, err := os.read_entire_file_from_path("settings.dat", context.allocator)
    defaultGameSettings: GameSettings = GameSettings{high_score = 0, first_run = true, keybind_scheme = .MOVE_IN_WASD_SKILLS_IN_ARROWS }

    if err != os.ERROR_NONE {
        fmt.println("settings.dat não encontrado. Assumindo primeira execução e configurações padrão.")
        return defaultGameSettings
    }

    defer delete(data, context.allocator)

    // Parse the data: "highscore;first_run_int;keybind_scheme_int"
    str_data := string(data)
    parts := strings.split(str_data, ";")
    number_of_itens_saved_in_file := 3

    if len(parts) != number_of_itens_saved_in_file {
        fmt.println("ERRO: settings.dat corrompido ou formato inválido. Revertendo para configurações padrão.")
        return defaultGameSettings
    }

    // HighScore
    val_highscore, ok_highscore := strconv.parse_f32(parts[0])
    if !ok_highscore {
        fmt.println("Erro ao parsear highscore em settings.dat. Revertendo valor para padrão.")
        val_highscore = 0
    }

    // First run
    val_first_run_int, ok_first_run_int := strconv.parse_int(parts[1])
    val_first_run := val_first_run_int == 1
    if !ok_first_run_int {
        fmt.println("Erro ao parsear first_run em settings.dat. Revertendo para valor padrão")
        val_first_run = true
    }

    // Keybind Scheme
    val_keybind_int, ok_keybind := strconv.parse_int(parts[2])
    val_keybind := KeybindScheme(val_keybind_int)
    if !ok_keybind || val_keybind_int < 0 || val_keybind_int >= int(KeybindScheme._COUNT) {
        fmt.println("Erro ao parsear keybind_scheme em settings.dat. Revertendo para o valor padrão.")
        val_keybind: KeybindScheme = .MOVE_IN_WASD_SKILLS_IN_ARROWS 
    }

    return GameSettings{ high_score = val_highscore, first_run = val_first_run, keybind_scheme = val_keybind }
}


deinit_game :: proc() {
    // liberar memória aqui
    raylib.UnloadTexture(player.texture_idle)
    raylib.UnloadTexture(player.texture_run)
    raylib.UnloadTexture(player.shield_texture)
    raylib.UnloadTexture(player.skill_icons_atlas_texture)
    raylib.UnloadTexture(player.frame_texture)
    raylib.UnloadTexture(player.key_q_texture)
    raylib.UnloadTexture(player.key_w_texture)
    raylib.UnloadTexture(player.key_e_texture)
    raylib.UnloadTexture(player.key_r_texture)
    raylib.UnloadTexture(player.key_a_texture)
    raylib.UnloadTexture(player.key_s_texture)
    raylib.UnloadTexture(player.key_d_texture)
    raylib.UnloadTexture(player.key_up_texture)
    raylib.UnloadTexture(player.key_right_texture)
    raylib.UnloadTexture(player.key_down_texture)
    raylib.UnloadTexture(player.key_left_texture)
    raylib.UnloadTexture(session_game_data.main_menu_background)
    raylib.UnloadTexture(session_game_data.enemy_texture)
    raylib.UnloadTexture(session_game_data.floor_texture)
    raylib.UnloadTexture(session_game_data.circle_texture)

    if enemies != nil do delete(enemies)

    enemies = nil

    save_game_settings()
    fmt.println("Memória limpa com sucesso. Até logo, Mago!")
}

// helpers
draw_centered_text :: proc(text: string, y: i32, size: i32, color: raylib.Color) {
    c_str := fmt.ctprintf(text)
    width := raylib.MeasureText(c_str, size)
    screen_w := raylib.GetScreenWidth()
    raylib.DrawText(c_str, screen_w / 2 - width / 2, y, size, color)
}

draw_keyboard_icon :: proc(key_texture: raylib.Texture2D, pos: raylib.Vector2, size: f32, color: raylib.Color) {
    source_rec := raylib.Rectangle {
        x = 0,
        y = 0,
        width = f32(key_texture.width),
        height = f32(key_texture.height),
    }

    dest_rec := raylib.Rectangle {
        x = pos.x,
        y = pos.y,
        width = size,
        height = size,
    }

    origin := raylib.Vector2{ size / 2, size / 2 }

    raylib.DrawTexturePro(key_texture, source_rec, dest_rec, origin, 0, color)
}