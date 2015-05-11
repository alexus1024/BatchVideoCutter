$ffmpeg = "E:\Program_Files\ffmpeg-20140906-git-1654ca7-win64-static\bin\"
$rules = "E:\dev\ffmpeg\testrules.xml"
$latestFfmpegUrl32 = 'http://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-latest-win32-static.7z'
$latestFfmpegUrl64 = 'http://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.7z'

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
chcp 65001
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if(!(Test-Path $ffmpeg)){

    $downloadPath = 'ffmpeg.7z'
    Write-Output ('Не нейден ffmpeg. Скачиваем в {0}...' -f $downloadPath)

    $downloadUrl =     if ([environment]::Is64BitOperatingSystem) {$latestFfmpegUrl64} else {$latestFfmpegUrl32}

    $web = New-Object System.Net.WebClient
    #$web.DownloadFile($downloadUrl, $downloadPath)

   explorer $downloadPath;
   $fullDownloadPath = [System.IO.Path]::GetFullPath($downloadPath)
   Write-Output 'Распакуйте и укажите путь в переменную $ffmpeg'
   break
}

if(!(Test-Path $rules)){
    Write-Error 'Не найден файл с правилами'
    break
}

# предварительные проверки
$notFoundInput = @()
foreach($nodeRaw in Select-Xml  "/work/cut" $rules){

    if(!(Test-Path $nodeRaw.Node.input)){
        $notFoundInput += $nodeRaw.Node.input
    }

    $outDir = [System.IO.Path]::GetDirectoryName($nodeRaw.Node.output)

    if($outDir -and !(Test-Path $outDir)){
        New-Item -ItemType directory -Path $outDir

        Write-Output "Создана директория $outDir"
    }
}

if($notFoundInput.Count -gt 0){
    Write-Error "Some input files not exist: $notFoundInput"
}


# проверка логотипа
$logoInfo = Select-Xml  "/work[@logo]" $rules
$logoFilename = $logoInfo.Node.logo

if($logoFilename -and -not (Test-Path($logoFilename))){
    Write-Error "Файл логотипа не найден. $logoFilename"
}else{
    Write-Output "Используется логотип из файла. $logoFilename"
}


# выполнение 
$counter = 1
$cutErrors = @()
foreach($nodeRaw in Select-Xml  "/work/cut" $rules){
    $node = $nodeRaw.Node

    
    if (!$node.len){
        $len = [timespan]$node.to - [timespan]$node.from
    }else{
        $len = $node.len;
    }
    
    if($logoFilename){
    # вставка логотипа включена
        $videoInfo = (& "$($ffmpeg)ffprobe.exe" -show_streams -of xml -loglevel quiet $node.input) | Out-String
        $videoStreamInfo = Select-Xml -Content $videoInfo -XPath "/ffprobe/streams/stream[@codec_type='video' and @width and @height][1]"

        $videoWidth = $videoStreamInfo.Node.width
        $videoHeight = $videoStreamInfo.Node.height

        $logoWidth = $videoWidth/10

        $ffmpegParams = "-i", $node.input, "-i", $logoFilename, "-filter_complex", "[1]scale=$($logoWidth):$($logoWidth)/a [logo]; [0][logo]overlay=main_w-overlay_w-10:10", "-ss", $node.from, "-t", $len, "-y", "-loglevel", "error", $node.output

    }else{
        # если логотип не вставляем - включаем копирование потогов, чтобы не пережимать видео
        $ffmpegParams = "-i", $node.input, "-ss", $node.from, "-c", "copy",  "-t", $len, "-y", "-loglevel", "error", $node.output    
    }
    

    $error.Clear()
    
    try{
        (& "$($ffmpeg)ffmpeg.exe" $ffmpegParams)
        Write-Output "Задача $counter выполнена..."
    }catch{
        
        Write-Warning "Задача $counter : Ошибка. $($_.Exception)"
        $cutErrors += $error
    }
    

    $counter++

}

Write-Output "Готово!"

if($cutErrors.Count -gt 0){
    Write-Error "При выолнении задач возникали ошибки"
}