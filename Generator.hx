package;

import haxe.Template;
import promises.Promise;
import promises.PromiseUtils;

using StringTools;

class Generator {
	#if vscode
	@:keep
	@:expose("activate")
    static function activate(context: vscode.ExtensionContext) {
		log("I am the Business Goose!!!");
		context.subscriptions.push(Vscode.commands.registerCommand("businessGoose.generate", main));
    }
	#end

	static function main() {
		log("Generating");
		generate();
	}

	static function generate() {
		final dir = #if vscode Vscode.workspace.workspaceFolders[0].uri.path #else "." #end;
		var t: haxe.Template;
		getContent('$dir/template.html').then(content -> {
			t = new haxe.Template(content);
			return createDirectory('$dir/out');
		}).then(_ -> {
			return readDirectory('$dir/pages/');	
		}).then(files -> {
			for (file in files) {
				getContent('$dir/pages/' + file).then(c -> {
					var content = c.split("\n");
					final title = content.shift();
					var body = "";
					for (l in content) {
						body += '$l\n';
					}
					saveContent('$dir/out/$file', t.execute({page_title: title, body: body.trim()}));
				});
			}
		}).then((_) ->{ 
			var p: Array<Promise<Bool>>= [];
			exists('$dir/assets/').then((b) -> {
				if (!b) return;
				readDirectory('$dir/assets/').then(files -> {
					for (file in files) {
						p.push(copy('$dir/assets/$file', '$dir/out/$file'));
					}
				});
			});
			return PromiseUtils.runAll(cast p);
		}).then((_) -> {
			log("Done");
		});
	}

	static inline function log(contents: String) {
		#if vscode
		Vscode.window.showInformationMessage(contents);
		#else
		Sys.println(contents);
		#end
	}

	static function getContent(path: String): Promise<String> {
		return new Promise((resolve, reject) -> {
			#if vscode
			Vscode.workspace.fs.readFile(vscode.Uri.parse(path)).then((h) -> {
				final d = new js.html.TextDecoder();
				resolve(d.decode(h.buffer));
			});
			#else
			resolve(sys.io.File.getContent(path));
			#end
		});
	}

	static function saveContent(path: String, content: String): Promise<Bool> {
		return new Promise((resolve, reject) -> {
			#if vscode
			final e = new js.html.TextEncoder();
			Vscode.workspace.fs.writeFile(vscode.Uri.parse(path), e.encode(content)).then((_) -> {
				resolve(true);
			});
			#else
			sys.io.File.saveContent(path, content);
			resolve(true);
			#end
		});
	}

	static function copy(fromPath: String, toPath: String): Promise<Bool> {
		#if vscode
		return new Promise((resolve, reject) -> {
			Vscode.workspace.fs.copy(vscode.Uri.parse(fromPath), vscode.Uri.parse(toPath), {overwrite: true}).then((_) -> {
				resolve(true);
			});
			resolve(false);
		});
		#else
		return getContent(fromPath).then(c -> {
			saveContent(toPath, c);
		});
		#end
	}

	static function createDirectory(path: String): Promise<Bool> {
		return new Promise((resolve, reject) -> {
			#if vscode
			Vscode.workspace.fs.createDirectory(vscode.Uri.parse(path)).then((_) -> {
				resolve(true);
			});
			#else
			sys.FileSystem.createDirectory(path);
			resolve(true);
			#end
		});
	}

	static function readDirectory(path: String): Promise<Array<String>> {
		return new Promise((resolve, reject) -> {
			#if vscode
				Vscode.workspace.fs.readDirectory(vscode.Uri.parse(path)).then(h -> {
					resolve([for (f in h) f.name]);
				});
			#else
			resolve(sys.FileSystem.readDirectory(path));
			#end
		});
	}

	static function exists(path: String): Promise<Bool> {
		return new Promise((resolve, reject) -> {
			#if vscode
			resolve(true);
			//Vscode.workspace.fs.stat(vscode.Uri.parse(path)).then((_) -> {
			//	resolve(true);
			//});
			//resolve(false);
			#else
			resolve(sys.FileSystem.exists(path));
			#end
		});
	}
}
