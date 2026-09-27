param([Parameter(Mandatory=$true)][string]$ScriptPath)
$client=[System.Net.Sockets.TcpClient]::new('127.0.0.1',9876)
$client.ReceiveTimeout=120000
try {
    $stream=$client.GetStream()
    $writer=[System.IO.StreamWriter]::new($stream)
    $writer.AutoFlush=$true
    $reader=[System.IO.StreamReader]::new($stream)
    $writer.WriteLine((@{id='character-preparation';command='python.execute';params=@{script_path=$ScriptPath;timeout_seconds=110}} | ConvertTo-Json -Depth 6 -Compress))
    $response=$reader.ReadLine() | ConvertFrom-Json
    if (-not $response.success) { throw $response.error }
    $response.result.stdout
    if ($response.result.error) { throw $response.result.error }
} finally { $client.Dispose() }
