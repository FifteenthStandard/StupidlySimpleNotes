global using System.CommandLine;

var root = Path.Join(
    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
    "ssn"
);

var app = new AppCommand
{
    new NewCommand(root),
    new GetCommand(root),
    new ListCommand(root),
    new SearchCommand(root),
    new MoveCommand(root),
};

return await app.InvokeAsync(args);
