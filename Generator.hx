package;

import haxe.Template;

using StringTools;

class Generator {
	#if vscode
	@:keep
	@:expose("activate")
    static function activate(context: vscode.ExtensionContext) {
		log("I am the Business Goose");
		context.subscriptions.push(Vscode.commands.registerCommand("businessGoose.generate", main));
    }
	#end

	static function main() {
		log("Generating");
		generate();
	}

	static function generate() {
		final dir = #if vscode Vscode.workspace.workspaceFolders[0].uri.path #else "." #end;
		var t = new haxe.Template(sys.io.File.getContent('$dir/template.html'));
		sys.FileSystem.createDirectory('$dir/out');
		for (file in sys.FileSystem.readDirectory('$dir/pages/')) {
			var content: Array<String> = sys.io.File.getContent('$dir/pages/' + file).split("\n");
			final title = content.shift();
			var body = "";
			for (l in content) {
				body += '$l\n';
			}
			sys.io.File.saveContent('$dir/out/$file', t.execute({page_title: title, body: body.trim()}));
		}
		if (sys.FileSystem.exists('$dir/assets/')) {
			for (file in sys.FileSystem.readDirectory('$dir/assets/')) {
				sys.io.File.saveContent('$dir/out/$file', sys.io.File.getContent('$dir/assets/$file'));
			}
		}
		log("Done");
	}

	static inline function log(contents: String) {
		#if vscode
		Vscode.window.showInformationMessage(contents);
		#else
		Sys.println(contents);
		#end
	}
}
