using System.Diagnostics;

public static class Editor
{
    public static string Root { get; set; } = "";
    private static string EditorPath => Path.Join(Root, ".editor");
    public static Task<string> Get() => 
        File.Exists(EditorPath)
            ? File.ReadAllTextAsync(EditorPath)
            : Task.FromResult("code --wait");
    public static Task Set(string editorCommand)
        => File.WriteAllTextAsync(EditorPath, editorCommand);
    public static async Task Edit(string path)
        => await Process.Start("cmd", $"/c {await Get()} \"{path}\"").WaitForExitAsync();
}