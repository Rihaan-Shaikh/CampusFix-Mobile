$url = "https://campusfixed.netlify.app/api/auth/sign-in/social"
try {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Timeout = 8000
    $req.Method = "POST"
    $req.ContentType = "application/json"
    $body = '{"provider":"google","idToken":{"token":"dummy_id_token"}}'
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $req.ContentLength = $bodyBytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bodyBytes, 0, $bodyBytes.Length)
    $stream.Close()
    
    $resp = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
    Write-Host "POST $url (idToken) -> $([int]$resp.StatusCode)"
    Write-Host "  Response: $($reader.ReadToEnd())"
} catch [System.Net.WebException] {
    $res = $_.Exception.Response
    if ($res -ne $null) {
        $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
        Write-Host "POST $url (idToken) -> $([int]$res.StatusCode)"
        Write-Host "  Response: $($reader.ReadToEnd())"
    } else {
        Write-Host "POST $url (idToken) -> Error: $($_.Exception.Message)"
    }
}
