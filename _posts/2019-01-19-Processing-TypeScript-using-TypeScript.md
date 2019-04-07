---
layout: post
title: Processing TypeScript using TypeScript
tags: typescript javascript
toc: true
---

One of the interesting things about TypeScript is that it exposes a compiler API that you can use to process TypeScript code programmatically, from your own TypeScript code. This post will give you some idea of how this can be done and why it can be useful.

## The TypeScript compiler API

When writing an application using TypeScript, you typically use the "typescript" module as a build tool to transpile your TypeScript code into JavaScript. This is usually all you need. However, if you import the "typescript" module in your application code, you get access to the compiler API. This compiler API provides some very powerful tools for interacting with TypeScript code. Some of its features are documented on the TypeScript wiki: [Using the Compiler API](https://github.com/Microsoft/TypeScript/wiki/Using-the-Compiler-API).

## SourceFiles and the abstract syntax tree (AST)

A SourceFile is perhaps the most basic form of processed TypeScript code. A TypeScript SourceFile contains a representation of the source code itself, from which you can extract the *abstract syntax tree (AST)* for the code. An AST represents the syntactical structure of the program as a tree, starting from the SourceFile itself and drilling down into the statements and their building blocks. In general, compilers or interpreters typically construct an AST as an initial step in the processing of the source code.

As an example, consider the following simple TypeScript code:

```typescript
const test: number = 1 + 2;
```

Now, let's write some code that creates a SourceFile for this code and prints the AST.

```typescript
import * as ts from "typescript";

const filename = "test.ts";
const code = `const test: number = 1 + 2;`;

const sourceFile = ts.createSourceFile(
    filename, code, ts.ScriptTarget.Latest
);

function printRecursiveFrom(
    node: ts.Node, indentLevel: number, sourceFile: ts.SourceFile
) {
    const indentation = "-".repeat(indentLevel);
    const syntaxKind = ts.SyntaxKind[node.kind];
    const nodeText = node.getText(sourceFile);
    console.log(`${indentation}${syntaxKind}: ${nodeText}`);

    node.forEachChild(child =>
        printRecursiveFrom(child, indentLevel + 1, sourceFile)
    );
}

printRecursiveFrom(sourceFile, 0, sourceFile);
```

This prints the following AST:

```
SourceFile: const test: number = 1 + 2;
-VariableStatement: const test: number = 1 + 2;
--VariableDeclarationList: const test: number = 1 + 2
---VariableDeclaration: test: number = 1 + 2
----Identifier: test
----NumberKeyword: number
----BinaryExpression: 1 + 2
-----FirstLiteralToken: 1
-----PlusToken: +
-----FirstLiteralToken: 2
-EndOfFileToken:
```

Here, we used `ts.Node.forEachChild()` to get the children for a node in the AST. There is an alternative to this, `ts.Node.getChildren(sourceFile).forEach()`, which creates a more detailed AST:

```
SourceFile: const test: number = 1 + 2;
-SyntaxList: const test: number = 1 + 2;
--VariableStatement: const test: number = 1 + 2;
---VariableDeclarationList: const test: number = 1 + 2
----ConstKeyword: const
----SyntaxList: test: number = 1 + 2
-----VariableDeclaration: test: number = 1 + 2
------Identifier: test
------ColonToken: :
------NumberKeyword: number
------FirstAssignment: =
------BinaryExpression: 1 + 2
-------FirstLiteralToken: 1
-------PlusToken: +
-------FirstLiteralToken: 2
---SemicolonToken: ;
-EndOfFileToken:
```

Looking at generated ASTs is an interesting way to learn more about the TypeScript language and how the compiler represents source code internally. If you want to look at ASTs in a more interactive way and view more information for the nodes in the tree, I recommend using [TypeScript AST Viewer](https://ts-ast-viewer.com/).

## Turning code into a Program

While SourceFiles are easy to create, the functionality they offer doesn't always suffice. In order to do more interesting things like getting diagnostics or using the type checker, you need a Program.

Obtaining a Program from a file on disk is pretty straightforward. As the following example shows, this can be a one-liner in very simple cases.

```typescript
const program = ts.createProgram(["src/test.ts"], {});
```

Getting a Program from a simple string of TypeScript code is a bit more tricky. In order to accomplish this, we need to specify a custom CompilerHost instance that will be used by the compiler to retrieve and write files.

```typescript
import * as ts from "typescript";

const filename = "test.ts";
const code = `const test: number = 1 + 2;`;

const sourceFile = ts.createSourceFile(
    filename, code, ts.ScriptTarget.Latest
);

const defaultCompilerHost = ts.createCompilerHost({});

const customCompilerHost: ts.CompilerHost = {
    getSourceFile: (name, languageVersion) => {
        console.log(`getSourceFile ${name}`);

        if (name === filename) {
            return sourceFile;
        } else {
            return defaultCompilerHost.getSourceFile(
                name, languageVersion
            );
        }
    },
    writeFile: (filename, data) => {},
    getDefaultLibFileName: () => "lib.d.ts",
    useCaseSensitiveFileNames: () => false,
    getCanonicalFileName: filename => filename,
    getCurrentDirectory: () => "",
    getNewLine: () => "\n",
    getDirectories: () => [],
    fileExists: () => true,
    readFile: () => ""
};

const program = ts.createProgram(
    ["test.ts"], {}, customCompilerHost
);

// getSourceFile test.ts
// getSourceFile lib.d.ts
```

As you can see, the `getSourceFile` method of the CompilerHost is called twice: once for getting the actual code we want to compile and once for getting `lib.d.ts`, the default library specifying the JavaScript/TypeScript features that are available to the code.

## Transpiling code

Transpiling code from TypeScript to plain JavaScript using the compiler API is pretty straightforward. In its simplest form, it takes one line of code.

```typescript
const code = `const test: number = 1 + 2;`;
const transpiledCode = ts.transpileModule(code, {}).outputText;
console.log(transpiledCode); // var test = 1 + 2;
```

It is possible to pass several options to the `transpileModule` method, including the compiler options to use.

You can also transpile code by invoking the `emit()` method on a Program. If you do this for a program created in the most simple way from an actual file on disk, this will put a transpiled .js file next to it. As an example, let's write a piece of TypeScript code that will transpile itself when run.

```typescript
// file test.ts

import * as ts from "typescript";

const program = ts.createProgram(["src/test.ts"], {});
program.emit();
```

When this code is transpiled and run, it creates the following JavaScript file next to the test.ts file:

```javascript
// file test.js

"use strict";
exports.__esModule = true;
var ts = require("typescript");
var program = ts.createProgram(["src/test.ts"], {});
program.emit();
```

It is also interesting to note that, if the file you transpile imports other TypeScript files, those will also be transpiled if the compiler can find them.

## Getting diagnostics

If you have a Program, you can use that Program to obtain diagnostics for the code. In order to get the compiler errors or warnings, use the `getPreEmitDiagnostics()` method. As an example, take a look at the following code which prints its own diagnostics.

```typescript
import * as ts from "typescript";

let test: number = "test"; // compiler error

const program = ts.createProgram(["src/test.ts"], {});
const diagnostics = ts.getPreEmitDiagnostics(program);

for (const diagnostic of diagnostics) {
    const message = diagnostic.messageText;
    const file = diagnostic.file;
    const filename = file.fileName;

    const lineAndChar = file.getLineAndCharacterOfPosition(
        diagnostic.start
    );

    const line = lineAndChar.line + 1;
    const character = lineAndChar.character + 1;

    console.log(message);
    console.log(`(${filename}:${line}:${character})`);
}

// Type '"test"' is not assignable to type 'number'.
// (src/test.ts:3:5)
```

## Getting type information

Another thing that a Program allows you to do is to obtain a TypeChecker for extracting type information from nodes in the AST. The following code obtains a TypeChecker for itself and uses the checker to emit the types of all variable declarations in the code.

```typescript
import * as ts from "typescript";

const filename = "src/test.ts";
const program = ts.createProgram([filename], {});
const sourceFile = program.getSourceFile(filename);
const typeChecker = program.getTypeChecker();

function recursivelyPrintVariableDeclarations(
    node: ts.Node, sourceFile: ts.SourceFile
) {
    if (ts.isVariableDeclaration(node))  {
        const nodeText = node.getText(sourceFile);
        const type = typeChecker.getTypeAtLocation(node);
        const typeName = typeChecker.typeToString(type, node);

        console.log(nodeText);
        console.log(`(${typeName})`);
    }

    node.forEachChild(child =>
        recursivelyPrintVariableDeclarations(child, sourceFile)
    );
}

recursivelyPrintVariableDeclarations(sourceFile, sourceFile);

// filename = "src/test.ts"
// ("src/test.ts")
// program = ts.createProgram([filename], {})
// (ts.Program)
// sourceFile = program.getSourceFile(filename)
// (ts.SourceFile)
// typeChecker = program.getTypeChecker()
// (ts.TypeChecker)
// nodeText = node.getText(sourceFile)
// (string)
// type = typeChecker.getTypeAtLocation(node)
// (ts.Type)
// typeName = typeChecker.typeToString(type, node)
// (string)
```

## Use case: creating a custom linter

The TypeScript compiler API makes it pretty straightforward to create your own custom linter that generates errors or warnings if it finds certain things in the code. For an example, see this part of the compiler API documentation: [Traversing the AST with a little linter](https://github.com/Microsoft/TypeScript/wiki/Using-the-Compiler-API#traversing-the-ast-with-a-little-linter). Note that the code uses the kind SyntaxKind of the node (`node.kind`) to determine the kind of node and then casts the node to its specific type, allowing for convenient access to certain child nodes.

The example above doesn't create a Program, because there is no need to create one. If the information in the AST suffices for your linter, it is easier and more efficient to just create a SourceFile directly. More advanced linters may need type checking, which means you will need to generate a Program for the code to be linted in order to obtain a TypeChecker.

## Use case: extracting type documentation

The documentation for the compiler API includes an example that uses a TypeChecker to extract and emit type documentation for the code: [Using the Type Checker](https://github.com/Microsoft/TypeScript/wiki/Using-the-Compiler-API#using-the-type-checker)

## Use case: altering or creating code programmatically

It is possible that you want to analyze some TypeScript source code and then alter it in some cases. One way to do this is to traverse the AST and generate a list of changes you want to perform on the code (e.g., remove 2 characters starting from position 11 and insert the string "test" instead). Then, take the source code as a string and apply the changes in reverse order (starting from the end of the source code, so your changes don't affect the positions where the other changes need to happen).

You can also programmatically create AST nodes and use them to programmatically generate new TypeScript code.

```typescript
import * as ts from "typescript";

const statement = ts.createVariableStatement(
    [],
    ts.createVariableDeclarationList(
        [ts.createVariableDeclaration(
            ts.createIdentifier("testVar"),
            ts.createKeywordTypeNode(ts.SyntaxKind.StringKeyword),
            ts.createStringLiteral("test")
        )],
        ts.NodeFlags.Const
    )
);

const printer = ts.createPrinter();

const result = printer.printNode(
    ts.EmitHint.Unspecified,
    statement,
    undefined
);

console.log(result); // const testVar: string = "test";
```

The TypeScript compiler API also allows you to define transformers that walk the AST and replace nodes by new ones as needed. The following code finds all identifiers in the `SourceFile` and adds a suffix `suffix` to them.

```typescript
import * as ts from "typescript";

const filename = "test.ts";
const code = `const test: number = 1 + 2;`;

const sourceFile = ts.createSourceFile(
    filename, code, ts.ScriptTarget.Latest
);

const transformerFactory: ts.TransformerFactory<ts.Node> = (
    context: ts.TransformationContext
) => {
    return (rootNode) => {
        function visit(node: ts.Node): ts.Node {
            node = ts.visitEachChild(node, visit, context);

            if (ts.isIdentifier(node)) {
                return ts.createIdentifier(node.text + "suffix");
            } else {
                return node;
            }
        }

        return ts.visitNode(rootNode, visit);
    };
};

const transformationResult = ts.transform(
    sourceFile, [transformerFactory]
);

const transformedSourceFile = transformationResult.transformed[0];
const printer = ts.createPrinter();

const result = printer.printNode(
    ts.EmitHint.Unspecified,
    transformedSourceFile,
    undefined
);

console.log(result); // const testsuffix: number = 1 + 2;
```

## Resources

- [Using the Compiler API](https://github.com/Microsoft/TypeScript/wiki/Using-the-Compiler-API)
- [Abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree)
- [TypeScript AST Viewer](https://ts-ast-viewer.com/)