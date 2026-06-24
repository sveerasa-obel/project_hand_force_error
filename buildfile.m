function plan = buildfile
plan = buildplan(localfunctions);
plan.DefaultTasks = "pushToGitHub";
end

function exportTask(~)
% Task 1: Convert the live script to markdown
% CHANGE 'my_script' to match your actual file name
fprintf('Converting live script to markdown...\n');
matlab.internal.liveeditor.openAndConvert('force_transformation_v2.mlx', 'force_transformation_v2.md'); %Change the code conversions here
end

function pushToGitHubTask(~)
% Task 2: Automatically push the changes to GitHub
% This task automatically waits for the exportTask to finish first
pushToGitHubTask.Dependencies = "export";

fprintf('Staging files for Git...\n');
[status1, cmdout1] = system('git add force_transformation_v2.mlx force_transformation_v2.md buildfile.m');

if status1 == 0
    fprintf('Committing changes...\n');
    system('git commit -m "Automated update from MATLAB buildtool"');
    
    fprintf('Pushing to GitHub repository...\n');
    [status3, cmdout3] = system('git push origin main');
    
    if status3 == 0
        fprintf('Success! GitHub repository updated.\n');
    else
        fprintf('Push failed. Error details:\n%s\n', cmdout3);
    end
else
    fprintf('Git staging failed. Make sure Git is installed on your machine:\n%s\n', cmdout1);
end
end
