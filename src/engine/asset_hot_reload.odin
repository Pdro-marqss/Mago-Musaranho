package engine

import "vendor:raylib"
import "core:os"
import "core:fmt"
import "core:time"

// Struct/type da textura sendo observada
WatchedTexture :: struct {
    texture: raylib.Texture2D,
    path: string,
    last_pushed: time.Time,
}

// Cria e carrega uma textura monitorada pela engine. Usamos no lugar do raylib.LoadTexture() padrao
Make_Watched_Texture :: proc(path: string) -> WatchedTexture {
    watchedTexture: WatchedTexture
    
    watchedTexture.path = path

    pathInCString := fmt.ctprintf(path)
    
    watchedTexture.texture = raylib.LoadTexture(pathInCString)

    info, err := os.stat(path, context.allocator)
    if err == os.ERROR_NONE {
        watchedTexture.last_pushed = info.modification_time

        // limpando a memória pós uso
        os.file_info_delete(info, context.allocator)
    } else {
        fmt.eprintln("Erro ao ler timestamp inicial do asset: ", path)
    }

    return watchedTexture
}

// Verifica se o arquivo foi modificado. Se sim, recarrega e retorna true
Update_Watched_Texture :: proc(watchedTexture: ^WatchedTexture) -> bool {
    info, err := os.stat(watchedTexture.path, context.allocator)
    if err != os.ERROR_NONE do return false

    // Garante que a struct info seja deletada antes da procedure terminar
    defer os.file_info_delete(info, context.allocator)

    // Se o tempo da textura salva em disco for maior (depois) do que o último que regristramos
    if time.diff(watchedTexture.last_pushed, info.modification_time) > 0 {
        raylib.UnloadTexture(watchedTexture.texture)

        pathInCString := fmt.ctprintf(watchedTexture.path)

        watchedTexture.texture = raylib.LoadTexture(pathInCString)

        watchedTexture.last_pushed = info.modification_time

        raylib.SetTextureFilter(watchedTexture.texture, .POINT)

        fmt.println("--- ASSET CARREGADO COM SUCESSO ---")

        return true
    }

    return false
}