function save-es {
    # Step 1: Git status
    git status

    # Step 2: Git add .
    git add .

    # Step 3: Git commit -m
    $commitMessage = "standard"
    if ($args.Count -gt 0) {
        $commitMessage = $args[0]
    }
    git commit -m $commitMessage

    # Step 4: Git push origin master
    git push origin master
}

Export-ModuleMember -Function save-es
