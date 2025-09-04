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
            $ResizedBitmap = New-Object System.Drawing.Bitmap($Bitmap, 144, 144)
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
        
        # Set up overlay properties - larger for Stream Deck visibility
        $OverlaySize = [int]($BaseImage.Width * 0.6)  # 60% of icon size (was 40%)
        $OverlayX = $BaseImage.Width - $OverlaySize - 1
        $OverlayY = $BaseImage.Height - $OverlaySize - 1
        
        # Create overlay background circle with distinctive colors per overlay type
        switch ($OverlayType) {
            "focus" {
                # Blue background for focus
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 65, 105, 225))  # Royal Blue
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 2)  # White border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # White symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
            "restart" {
                # Orange background for restart
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 140, 0))  # Dark Orange
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 2)  # White border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # White symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
            "start" {
                # Green background for start
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 34, 139, 34))  # Forest Green
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 2)  # White border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # White symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
            "stop" {
                # Red background for stop
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 220, 20, 60))  # Crimson
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 2)  # White border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # White symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
        }
        
        $Graphics.FillEllipse($OverlayBrush, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        $Graphics.DrawEllipse($BorderPen, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
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
        StartIconPath = $null
        StopIconPath = $null
        HasIcon = $false
        HasFocusIcon = $false
        HasRestartIcon = $false
        HasStartIcon = $false
        HasStopIcon = $false
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
        
        # Create start icon with play overlay
        $StartFileName = "$SafeProgramName" + "_start.png"
        $StartIconPath = Join-Path $IconsDir $StartFileName
        $HasStartIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $StartIconPath -OverlayType "start"
        if ($HasStartIcon) {
            Write-Log "Created start icon for $($Program.name)"
            $IconResults.StartIconPath = "icons\$StartFileName"
            $IconResults.HasStartIcon = $true
        }
        
        # Create stop icon with stop overlay
        $StopFileName = "$SafeProgramName" + "_stop.png"
        $StopIconPath = Join-Path $IconsDir $StopFileName
        $HasStopIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $StopIconPath -OverlayType "stop"
        if ($HasStopIcon) {
            Write-Log "Created stop icon for $($Program.name)"
            $IconResults.StopIconPath = "icons\$StopFileName"
            $IconResults.HasStopIcon = $true
        }
    }
    
    return $IconResults
}

function Add-GlobalIconOverlay {
    param(
        [string]$BaseIconPath,
        [string]$OutputPath,
        [string]$OverlayType  # "startall", "stopall"
    )
    
    try {
        if (-not (Test-Path $BaseIconPath)) {
            Write-Log "WARNING: Base icon not found at $BaseIconPath"
            return $false
        }
        
        Write-Log "Creating $OverlayType global overlay icon from $BaseIconPath to $OutputPath"
        
        # Load the base icon
        $BaseImage = [System.Drawing.Image]::FromFile($BaseIconPath)
        $Canvas = New-Object System.Drawing.Bitmap($BaseImage.Width, $BaseImage.Height)
        $Graphics = [System.Drawing.Graphics]::FromImage($Canvas)
        
        # Draw the base image
        $Graphics.DrawImage($BaseImage, 0, 0)
        
        # Set up overlay properties - bigger, centered, with opacity
        $OverlaySize = [int]($BaseImage.Width * 0.8)  # 80% of icon size (much bigger than individual 60%)
        $CenterX = $BaseImage.Width / 2
        $CenterY = $BaseImage.Height / 2
        $OverlayX = $CenterX - ($OverlaySize / 2)
        $OverlayY = $CenterY - ($OverlaySize / 2)
        
        # Create overlay background circle with opacity and distinctive colors for global actions
        switch ($OverlayType) {
            "startall" {
                # Semi-transparent green background for Start All
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 34, 139, 34))  # Green with opacity
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # Thicker white border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 4)  # Thicker white symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
            "stopall" {
                # Semi-transparent red background for Stop All
                $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 220, 20, 60))  # Red with opacity
                $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 3)  # Thicker white border
                $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 4)  # Thicker white symbol
                $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))  # White fill
            }
        }
        
        $Graphics.FillEllipse($OverlayBrush, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        $Graphics.DrawEllipse($BorderPen, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
        $SymbolCenterX = $CenterX
        $SymbolCenterY = $CenterY
        
        switch ($OverlayType) {
            "startall" {
                # Draw larger play triangle for Start All
                $TriangleSize = [int]($OverlaySize * 0.5)  # Bigger triangle
                $TrianglePoints = @(
                    (New-Object System.Drawing.Point(($SymbolCenterX - $TriangleSize/3), ($SymbolCenterY - $TriangleSize/2))),
                    (New-Object System.Drawing.Point(($SymbolCenterX - $TriangleSize/3), ($SymbolCenterY + $TriangleSize/2))),
                    (New-Object System.Drawing.Point(($SymbolCenterX + $TriangleSize/2), $SymbolCenterY))
                )
                $Graphics.FillPolygon($SymbolBrush, $TrianglePoints)
            }
            "stopall" {
                # Draw larger square for Stop All
                $SquareSize = [int]($OverlaySize * 0.6)  # Bigger square
                $SquareRect = New-Object System.Drawing.Rectangle(($SymbolCenterX - $SquareSize/2), ($SymbolCenterY - $SquareSize/2), $SquareSize, $SquareSize)
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
        Write-Log "WARNING: Could not create global overlay icon: $($_.Exception.Message)"
        return $false
    }
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
        # Create StartAll icon with larger, centered, semi-transparent play overlay
        $StartAllIconPath = Join-Path $IconsDir "StartAll.png"
        $HasStartAllIcon = Add-GlobalIconOverlay -BaseIconPath $BaseIconPath -OutputPath $StartAllIconPath -OverlayType "startall"
        if ($HasStartAllIcon) {
            Write-Log "Created StartAll icon with large centered play overlay"
            $GlobalIcons.StartAllIconPath = "icons\StartAll.png"
            $GlobalIcons.HasStartAllIcon = $true
        }
        
        # Create StopAll icon with larger, centered, semi-transparent stop overlay
        $StopAllIconPath = Join-Path $IconsDir "StopAll.png"
        $HasStopAllIcon = Add-GlobalIconOverlay -BaseIconPath $BaseIconPath -OutputPath $StopAllIconPath -OverlayType "stopall"
        if ($HasStopAllIcon) {
            Write-Log "Created StopAll icon with large centered stop overlay"
            $GlobalIcons.StopAllIconPath = "icons\StopAll.png"
            $GlobalIcons.HasStopAllIcon = $true
        }
    }
    
    return $GlobalIcons
}