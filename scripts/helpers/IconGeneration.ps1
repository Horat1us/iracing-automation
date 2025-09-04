# Icon Generation Helper Functions
# Contains functions for extracting and creating overlay icons

Add-Type -AssemblyName System.Drawing

# Ensure System.Drawing is loaded for icon overlay operations
Add-Type -AssemblyName System.Windows.Forms

function Extract-Icon {
    param(
        [string]$ExecutablePath,
        [string]$OutputPath
    )
    
    try {
        $Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExecutablePath)
        if ($Icon) {
            $Bitmap = $Icon.ToBitmap()
            $ResizedBitmap = New-Object System.Drawing.Bitmap($Bitmap, 72, 72)
            $ResizedBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $ResizedBitmap.Dispose()
            $Bitmap.Dispose()
            $Icon.Dispose()
            return $true
        }
    }
    catch {
        Write-Log "WARNING: Could not extract icon from $ExecutablePath : $($_.Exception.Message)"
    }
    return $false
}

function Add-IconOverlay {
    param(
        [string]$BaseIconPath,
        [string]$OutputPath,
        [string]$OverlayType  # "focus", "restart", "start", "stop"
    )
    
    try {
        if (-not (Test-Path $BaseIconPath)) {
            Write-Log "WARNING: Base icon not found at $BaseIconPath"
            return $false
        }
        
        Write-Log "Creating $OverlayType overlay icon from $BaseIconPath to $OutputPath"
        
        # Load the base icon
        $BaseImage = [System.Drawing.Image]::FromFile($BaseIconPath)
        $Canvas = New-Object System.Drawing.Bitmap($BaseImage.Width, $BaseImage.Height)
        $Graphics = [System.Drawing.Graphics]::FromImage($Canvas)
        
        # Draw the base image
        $Graphics.DrawImage($BaseImage, 0, 0)
        
        # Set up overlay properties
        $OverlaySize = [int]($BaseImage.Width * 0.4)  # 40% of icon size
        $OverlayX = $BaseImage.Width - $OverlaySize - 2
        $OverlayY = $BaseImage.Height - $OverlaySize - 2
        
        # Create overlay background circle
        $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
        $Graphics.FillEllipse($OverlayBrush, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
        # Draw overlay border
        $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 0, 0), 1)
        $Graphics.DrawEllipse($BorderPen, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
        # Draw overlay symbol
        $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 0, 0, 0), 2)
        $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
        
        $CenterX = $OverlayX + ($OverlaySize / 2)
        $CenterY = $OverlayY + ($OverlaySize / 2)
        $SymbolRadius = [int]($OverlaySize * 0.25)
        
        switch ($OverlayType) {
            "focus" {
                # Draw eye symbol for focus
                $EyeWidth = [int]($OverlaySize * 0.6)
                $EyeHeight = [int]($OverlaySize * 0.35)
                $EyeRect = New-Object System.Drawing.Rectangle(($CenterX - $EyeWidth/2), ($CenterY - $EyeHeight/2), $EyeWidth, $EyeHeight)
                $Graphics.DrawEllipse($SymbolPen, $EyeRect)
                
                # Draw pupil
                $PupilSize = [int]($OverlaySize * 0.15)
                $Graphics.FillEllipse($SymbolBrush, ($CenterX - $PupilSize/2), ($CenterY - $PupilSize/2), $PupilSize, $PupilSize)
            }
            "restart" {
                # Draw circular arrow for restart
                $ArrowRadius = [int]($OverlaySize * 0.25)
                $ArrowRect = New-Object System.Drawing.Rectangle(($CenterX - $ArrowRadius), ($CenterY - $ArrowRadius), ($ArrowRadius * 2), ($ArrowRadius * 2))
                
                # Draw circular arrow (partial circle with arrow head)
                $Graphics.DrawArc($SymbolPen, $ArrowRect, -45, 270)
                
                # Draw arrow head
                $ArrowHeadSize = 4
                $ArrowPoints = @(
                    (New-Object System.Drawing.Point(($CenterX + $ArrowRadius - 2), ($CenterY - $ArrowRadius + 4))),
                    (New-Object System.Drawing.Point(($CenterX + $ArrowRadius + 2), ($CenterY - $ArrowRadius - 2))),
                    (New-Object System.Drawing.Point(($CenterX + $ArrowRadius - 6), ($CenterY - $ArrowRadius - 2)))
                )
                $Graphics.FillPolygon($SymbolBrush, $ArrowPoints)
            }
            "start" {
                # Draw play triangle for start
                $TriangleSize = [int]($OverlaySize * 0.4)
                $TrianglePoints = @(
                    (New-Object System.Drawing.Point(($CenterX - $TriangleSize/3), ($CenterY - $TriangleSize/2))),
                    (New-Object System.Drawing.Point(($CenterX - $TriangleSize/3), ($CenterY + $TriangleSize/2))),
                    (New-Object System.Drawing.Point(($CenterX + $TriangleSize/2), $CenterY))
                )
                $Graphics.FillPolygon($SymbolBrush, $TrianglePoints)
            }
            "stop" {
                # Draw square for stop
                $SquareSize = [int]($OverlaySize * 0.5)
                $SquareRect = New-Object System.Drawing.Rectangle(($CenterX - $SquareSize/2), ($CenterY - $SquareSize/2), $SquareSize, $SquareSize)
                $Graphics.FillRectangle($SymbolBrush, $SquareRect)
            }
        }
        
        # Save the result
        $Canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Cleanup
        $Graphics.Dispose()
        $Canvas.Dispose()
        $BaseImage.Dispose()
        $OverlayBrush.Dispose()
        $BorderPen.Dispose()
        $SymbolPen.Dispose()
        $SymbolBrush.Dispose()
        
        return $true
    }
    catch {
        Write-Log "WARNING: Could not create overlay icon: $($_.Exception.Message)"
        return $false
    }
}

function New-ProgramIcons {
    param(
        [PSCustomObject]$Program,
        [string]$IconsDir,
        [string]$SafeProgramName
    )
    
    $IconResults = @{
        BaseIconPath = $null
        FocusIconPath = $null
        RestartIconPath = $null
        HasIcon = $false
        HasFocusIcon = $false
        HasRestartIcon = $false
    }
    
    # Extract base icon from executable
    $BaseIconPath = Join-Path $IconsDir "$SafeProgramName.png"
    $IconExtracted = Extract-Icon -ExecutablePath $Program.path -OutputPath $BaseIconPath
    
    if ($IconExtracted) {
        Write-Log "Extracted base icon for $($Program.name)"
        $IconResults.BaseIconPath = "icons\$SafeProgramName.png"
        $IconResults.HasIcon = $true
        
        # Create focus icon with eye overlay
        $FocusFileName = "$SafeProgramName" + "_focus.png"
        $FocusIconPath = Join-Path $IconsDir $FocusFileName
        $HasFocusIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $FocusIconPath -OverlayType "focus"
        if ($HasFocusIcon) {
            Write-Log "Created focus icon for $($Program.name)"
            $IconResults.FocusIconPath = "icons\$FocusFileName"
            $IconResults.HasFocusIcon = $true
        }
        
        # Create restart icon with circular arrow overlay
        $RestartFileName = "$SafeProgramName" + "_restart.png"
        $RestartIconPath = Join-Path $IconsDir $RestartFileName
        $HasRestartIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $RestartIconPath -OverlayType "restart"
        if ($HasRestartIcon) {
            Write-Log "Created restart icon for $($Program.name)"
            $IconResults.RestartIconPath = "icons\$RestartFileName"
            $IconResults.HasRestartIcon = $true
        }
    }
    
    return $IconResults
}

function New-GlobalActionIcons {
    param(
        [string]$BaseIconPath,
        [string]$IconsDir
    )
    
    $GlobalIcons = @{
        StartAllIconPath = $null
        StopAllIconPath = $null
        HasStartAllIcon = $false
        HasStopAllIcon = $false
    }
    
    if (Test-Path $BaseIconPath) {
        # Create StartAll icon with play overlay
        $StartAllIconPath = Join-Path $IconsDir "StartAll.png"
        $HasStartAllIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $StartAllIconPath -OverlayType "start"
        if ($HasStartAllIcon) {
            Write-Log "Created StartAll icon with play overlay"
            $GlobalIcons.StartAllIconPath = "icons\StartAll.png"
            $GlobalIcons.HasStartAllIcon = $true
        }
        
        # Create StopAll icon with stop overlay
        $StopAllIconPath = Join-Path $IconsDir "StopAll.png"
        $HasStopAllIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $StopAllIconPath -OverlayType "stop"
        if ($HasStopAllIcon) {
            Write-Log "Created StopAll icon with stop overlay"
            $GlobalIcons.StopAllIconPath = "icons\StopAll.png"
            $GlobalIcons.HasStopAllIcon = $true
        }
    }
    
    return $GlobalIcons
}