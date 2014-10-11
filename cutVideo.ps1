$ffmpeg = "E:\Program_Files\ffmpeg-20140906-git-1654ca7-win64-static\bin\ffmpeg.exe"
$rules = "F:\CamVideo\2014-08-25-09-01 ФИТ\Ричард тайминг для резки.txt"
$latestFfmpegUrl32 = 'http://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-latest-win32-static.7z'
$latestFfmpegUrl64 = 'http://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.7z'


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

    if(!(Test-Path $outDir)){
        New-Item -ItemType directory -Path $outDir

        Write-Output "Создана директория $outDir"
    }
}

if($notFoundInput.Count -gt 0){
    Write-Error "Some input files not exist: $notFoundInput"
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
    ,
    $a = '-i', $node.input, '-ss', $node.from, '-c', 'copy', '-t', $len, '-acodec', 'copy', '-vcodec', 'copy', '-y', '-loglevel', 'error', $node.output

    
    $error.Clear()
    (& $ffmpeg $a)
    
    if($error.Count -gt 0){
        Write-Output "Ошибка при обработке задачи '$counter': $error"
        $cutErrors += $error
    }

    Write-Output "Задача $counter выполнена..."

    $counter++

}

Write-Output "Готово!"

if($cutErrors.Count -gt 0){
    Write-Error "Was errors"
}