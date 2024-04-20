function load-task-themes {
    param(
        [string]$user = "var"
    )

    # Dark Theme A
    $action = New-ScheduledTaskAction -Execute "C:\Windows\Resources\Themes\themeA.theme"
    $trigger = New-ScheduledTaskTrigger -Daily -At 6PM
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "Theme Scheduling" -TaskName "Dark ThemeA" -Description "Activates Dark Theme everyday at 6PM" -User $user -RunLevel Limited

    # Dark Theme B
    $action = New-ScheduledTaskAction -Execute "C:\Windows\Resources\Themes\themeB.theme"
    $trigger = New-ScheduledTaskTrigger -Daily -At 12AM
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "Theme Scheduling" -TaskName "Dark ThemeB" -Description "Activates Dark Theme everyday at 12AM" -User $user -RunLevel Limited

    # Light Theme C
    $action = New-ScheduledTaskAction -Execute "C:\Windows\Resources\Themes\themeC.theme"
    $trigger = New-ScheduledTaskTrigger -Daily -At 9AM
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "Theme Scheduling" -TaskName "Light ThemeC" -Description "Activates Light Theme everyday at 9AM" -User $user -RunLevel Limited

    # Light Theme D
    $action = New-ScheduledTaskAction -Execute "C:\Windows\Resources\Themes\themeD.theme"
    $trigger = New-ScheduledTaskTrigger -Daily -At 2PM
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "Theme Scheduling" -TaskName "Light ThemeD" -Description "Activates Light Theme everyday at 2PM" -User $user -RunLevel Limited
}

