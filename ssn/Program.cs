global using System.CommandLine;

var root = Path.Join(
    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
    "ssn"
);

Editor.Root = root;

var app = new AppCommand
{
    new NewCommand(root),
    new GetCommand(root),
    new ListCommand(root),
    new SearchCommand(root),
    new EditCommand(root),
    new MoveCommand(root),
    new EditorCommand(),
};

return await app.InvokeAsync(args);
